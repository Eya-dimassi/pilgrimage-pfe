import crypto from 'crypto';
import prisma from '../config/prisma';

export const generateToken = (): string => {
  return crypto.randomBytes(32).toString('hex');
};

export const hashToken = (plainToken: string): string => {
  return crypto.createHash('sha256').update(plainToken).digest('hex');
};

export const createPasswordToken = async (
  utilisateurId: string,
  type: 'SET_PASSWORD' | 'RESET_PASSWORD'
): Promise<string> => {
  // invalidate any existing unused tokens of same type
  await prisma.passwordToken.updateMany({
    where: { utilisateurId, type, usedAt: null },
    data: { usedAt: new Date() },
  });

  const plainToken = generateToken();
  const tokenHash = hashToken(plainToken);

  const expiresAt = new Date();
  if (type === 'SET_PASSWORD') {
    expiresAt.setDate(expiresAt.getDate() + 7);   // 7 days
  } else {
    expiresAt.setHours(expiresAt.getHours() + 1); // 1 hour
  }

  await prisma.passwordToken.create({
    data: { utilisateurId, tokenHash, type, expiresAt },
  });

  return plainToken;
};

export const verifyPasswordToken = async (plainToken: string) => {
  const tokenHash = hashToken(plainToken);

  const record = await prisma.passwordToken.findUnique({
    where: { tokenHash },
    include: { utilisateur: true },
  });

  if (!record) throw new Error('Token invalide');
  if (record.usedAt) throw new Error('Token déjà utilisé');
  if (record.expiresAt < new Date()) throw new Error('Token expiré');

  return record;
};

export const consumePasswordToken = async (tokenHash: string): Promise<void> => {
  await prisma.passwordToken.update({
    where: { tokenHash },
    data: { usedAt: new Date() },
  });
};