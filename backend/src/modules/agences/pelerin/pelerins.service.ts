import prisma from '../../../config/prisma';
import { createPasswordToken } from '../../../utils/token.utils';
import { sendActivationEmail } from '../../../utils/mailer.utils';
import crypto from 'crypto';

// Generates a short uppercase unique code for family linking and pilgrim lookup.
async function generateUniquePelerinCode() {
  while (true) {
    const code = crypto.randomBytes(4).toString('hex').toUpperCase();

    const existing = await prisma.pelerin.findUnique({
      where: { codeUnique: code },
      select: { id: true },
    });

    if (!existing) {
      return code;
    }
  }
}

type PelerinImportRow = {
  nom: string;
  prenom: string;
  email: string;
  telephone?: string;
  dateNaissance?: string;
  numeroPasseport?: string;
  nationalite?: string;
}

function normalizeImportValue(value: unknown) {
  return String(value ?? '').trim();
}

function normalizeImportRow(row: Partial<PelerinImportRow>): PelerinImportRow {
  return {
    nom: normalizeImportValue(row.nom),
    prenom: normalizeImportValue(row.prenom),
    email: normalizeImportValue(row.email).toLowerCase(),
    telephone: normalizeImportValue(row.telephone) || undefined,
    dateNaissance: normalizeImportValue(row.dateNaissance) || undefined,
    numeroPasseport: normalizeImportValue(row.numeroPasseport) || undefined,
    nationalite: normalizeImportValue(row.nationalite) || undefined,
  };
}

function isValidImportDate(value?: string) {
  if (!value) return true;
  return !Number.isNaN(new Date(value).getTime());
}

// ── CREATE ────────────────────────────────────────────────────────────────────
export const createPelerin = async (
  agenceId: string,
  createdById: string,
  data: {
    nom: string;
    prenom: string;
    email: string;
    telephone?: string;
    dateNaissance?: string;
    numeroPasseport?: string;
    nationalite?: string;
  }
) => {
  const existing = await prisma.utilisateur.findUnique({ where: { email: data.email } });
  if (existing) throw new Error('Un compte avec cet email existe déjà');
  const codeUnique = await generateUniquePelerinCode();

  const utilisateur = await prisma.utilisateur.create({
    data: {
      email: data.email,
      motDePasse: null,
      nom: data.nom,
      prenom: data.prenom,
      telephone: data.telephone,
      role: 'PELERIN',
      actif: false,
      createdById,
      pelerin: {
        create: {
          agenceId,
          codeUnique,
          nationalite: data.nationalite,
          numeroPasseport: data.numeroPasseport,
          dateNaissance: data.dateNaissance ? new Date(data.dateNaissance) : undefined,
        },
      },
    },
    include: { pelerin: true },
  });

  const plainToken = await createPasswordToken(utilisateur.id, 'SET_PASSWORD');
  await sendActivationEmail(utilisateur.email, utilisateur.prenom, plainToken);

  return {
    id: utilisateur.id,
    email: utilisateur.email,
    nom: utilisateur.nom,
    prenom: utilisateur.prenom,
    telephone: utilisateur.telephone,
    pelerinId: utilisateur.pelerin!.id,
    agenceId,
  };
};
export const importPelerins = async (
  agenceId: string,
  createdById: string,
  rows: Partial<PelerinImportRow>[],
) => {
  if (!Array.isArray(rows) || rows.length === 0) {
    throw new Error('Aucune ligne a importer');
  }

  if (rows.length > 500) {
    throw new Error('Le fichier depasse la limite de 500 pelerins par import');
  }

  const normalizedRows = rows.map(normalizeImportRow);
  const errors: string[] = [];
  const emailOccurrences = new Map<string, number[]>();

  normalizedRows.forEach((row, index) => {
    const lineNumber = index + 2;

    if (!row.nom || !row.prenom || !row.email) {
      errors.push(`Ligne ${lineNumber}: nom, prenom et email sont requis`);
    }

    if (row.email && !row.email.includes('@')) {
      errors.push(`Ligne ${lineNumber}: email invalide`);
    }

    if (!isValidImportDate(row.dateNaissance)) {
      errors.push(`Ligne ${lineNumber}: date de naissance invalide`);
    }

    if (row.email) {
      const existing = emailOccurrences.get(row.email) ?? [];
      existing.push(lineNumber);
      emailOccurrences.set(row.email, existing);
    }
  });

  for (const [email, lineNumbers] of emailOccurrences.entries()) {
    if (lineNumbers.length > 1) {
      errors.push(`Email en doublon dans le fichier: ${email} (lignes ${lineNumbers.join(', ')})`);
    }
  }

  const emails = normalizedRows
    .map((row) => row.email)
    .filter(Boolean);

  if (emails.length > 0) {
    const existingUsers = await prisma.utilisateur.findMany({
      where: {
        email: { in: emails },
      },
      select: {
        email: true,
      },
    });

    existingUsers.forEach((user) => {
      errors.push(`Email deja utilise: ${user.email}`);
    });
  }

  if (errors.length > 0) {
    const error = new Error('Le fichier contient des erreurs');
    (error as Error & { details?: string[] }).details = errors;
    throw error;
  }

  const imported: Array<{ email: string; nom: string; prenom: string }> = [];

  for (const row of normalizedRows) {
    await createPelerin(agenceId, createdById, row);
    imported.push({
      email: row.email,
      nom: row.nom,
      prenom: row.prenom,
    });
  }

  return {
    message: `${imported.length} pelerin(s) importe(s) avec succes`,
    importedCount: imported.length,
    imported,
  };
};

// ── GET ALL ───────────────────────────────────────────────────────────────────
export const getPelerins = async (agenceId: string) => {
  const list = await prisma.pelerin.findMany({
    where: { agenceId },
    include: {
      utilisateur: {
        select: {
          id: true,
          nom: true,
          prenom: true,
          email: true,
          telephone: true,
          actif: true,
          createdAt: true,
        },
      },
      groupes: {
        where: { actif: true },
        take: 1,
        orderBy: { dateDebut: 'desc' },
        include: {
          groupe: { select: { id: true, nom: true } },
        },
      },
    },
    orderBy: { createdAt: 'desc' },
  });

  return list.map((p) => {
    const membership = p.groupes?.[0] ?? null;
    return {
      ...p,
      groupeId: membership?.groupeId ?? null,
      groupe: membership?.groupe ?? null,
    };
  });
};

// ── GET ONE ───────────────────────────────────────────────────────────────────
export const getPelerinById = async (agenceId: string, pelerinId: string) => {
  const pelerin = await prisma.pelerin.findFirst({
    where: { id: pelerinId, agenceId },
    include: {
      utilisateur: {
        select: {
          id: true,
          nom: true,
          prenom: true,
          email: true,
          telephone: true,
          actif: true,
          createdAt: true,
        },
      },
      groupes: {
        where: { actif: true },
        take: 1,
        orderBy: { dateDebut: 'desc' },
        include: {
          groupe: { select: { id: true, nom: true, typeVoyage: true } },
        },
      },
    },
  });

  if (!pelerin) throw new Error('Pèlerin introuvable');
  const membership = pelerin.groupes?.[0] ?? null;
  return {
    ...pelerin,
    groupeId: membership?.groupeId ?? null,
    groupe: membership?.groupe ?? null,
  };
};

// ── UPDATE ────────────────────────────────────────────────────────────────────
export const updatePelerin = async (
  agenceId: string,
  pelerinId: string,
  data: {
    nom?: string;
    prenom?: string;
    telephone?: string;
    nationalite?: string;
    numeroPasseport?: string;
    dateNaissance?: string;
  }
) => {
  const pelerin = await prisma.pelerin.findFirst({ where: { id: pelerinId, agenceId } });
  if (!pelerin) throw new Error('Pèlerin introuvable');

  const { nom, prenom, telephone, ...pelerinFields } = data;

  if (nom || prenom || telephone) {
    await prisma.utilisateur.update({
      where: { id: pelerin.utilisateurId },
      data: {
        ...(nom && { nom }),
        ...(prenom && { prenom }),
        ...(telephone && { telephone }),
      },
    });
  }

  return prisma.pelerin.update({
    where: { id: pelerinId },
    data: {
      ...(pelerinFields.nationalite && { nationalite: pelerinFields.nationalite }),
      ...(pelerinFields.numeroPasseport && { numeroPasseport: pelerinFields.numeroPasseport }),
      ...(pelerinFields.dateNaissance && { dateNaissance: new Date(pelerinFields.dateNaissance) }),
    },
    include: {
      utilisateur: {
        select: { id: true, nom: true, prenom: true, email: true, telephone: true, actif: true },
      },
      groupes: {
        where: { actif: true },
        take: 1,
        orderBy: { dateDebut: 'desc' },
        include: {
          groupe: { select: { id: true, nom: true } },
        },
      },
    },
  }).then((p) => {
    const membership = p.groupes?.[0] ?? null;
    return {
      ...p,
      groupeId: membership?.groupeId ?? null,
      groupe: membership?.groupe ?? null,
    };
  });
};

// ── DELETE ────────────────────────────────────────────────────────────────────
export const deletePelerin = async (agenceId: string, pelerinId: string) => {
  const pelerin = await prisma.pelerin.findFirst({ where: { id: pelerinId, agenceId } });
  if (!pelerin) throw new Error('Pèlerin introuvable');

  await prisma.utilisateur.delete({ where: { id: pelerin.utilisateurId } });

  return { message: 'Pèlerin supprimé avec succès' };
};

/**
 * Renvoyer l'email d'activation à un pèlerin
 */
export const resendActivationEmail = async (pelerinId: string, agenceId: string) => {
  const pelerin = await prisma.pelerin.findFirst({
    where: { id: pelerinId, agenceId },
    include: {
      utilisateur: {
        select: {
          id: true,
          email: true,
          nom: true,
          prenom: true,
          actif: true,
          motDePasse: true,
        },
      },
    },
  });

  if (!pelerin) throw new Error('Pèlerin introuvable');

  if (pelerin.utilisateur.actif && pelerin.utilisateur.motDePasse) {
    throw new Error('Ce pèlerin a déjà activé son compte');
  }

  const activationToken = await createPasswordToken(pelerin.utilisateur.id, 'SET_PASSWORD');
  await sendActivationEmail(
    pelerin.utilisateur.email,
    pelerin.utilisateur.prenom || pelerin.utilisateur.nom,
    activationToken
  );

  return { message: "Email d'activation renvoyé avec succès" };
};


