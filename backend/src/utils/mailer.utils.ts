import nodemailer from 'nodemailer';
import { env } from '../config/env';

const transporter = nodemailer.createTransport({
  host: env.MAIL_HOST,
  port: env.MAIL_PORT,
  auth: {
    user: env.MAIL_USER,
    pass: env.MAIL_PASS,
  },
});

export const sendActivationEmail = async (
  email: string,
  nom: string,
  plainToken: string
): Promise<void> => {
  const link = `${env.APP_URL}/auth/set-password?token=${plainToken}`;

  await transporter.sendMail({
    from: env.MAIL_FROM,
    to: email,
    subject: 'Activez votre compte — Plateforme Hajj',
    html: `
      <h2>Bienvenue ${nom}</h2>
      <p>Votre compte a été créé. Cliquez sur le lien ci-dessous pour définir votre mot de passe:</p>
      <a href="${link}" style="
        background: #2563eb;
        color: white;
        padding: 12px 24px;
        border-radius: 6px;
        text-decoration: none;
        display: inline-block;
        margin: 16px 0;
      ">Activer mon compte</a>
      <p>Ce lien expire dans 7 jours.</p>
      <p>Si vous n'attendiez pas cet email, ignorez-le.</p>
    `,
  });
};
export const sendApprovalEmail = async (
  email: string,
  nomAgence: string
): Promise<void> => {
  await transporter.sendMail({
    from: env.MAIL_FROM,
    to: email,
    subject: 'Votre compte a été approuvé — Plateforme Hajj',
    html: `
      <h2>Félicitations, ${nomAgence} !</h2>
      <p>Votre demande d'accès à la plateforme Hajj/Umrah a été <strong>approuvée</strong>.</p>
      <p>Vous pouvez maintenant vous connecter avec votre email et mot de passe.</p>
      <a href="${env.APP_URL}/login" style="
        background: #16a34a;
        color: white;
        padding: 12px 24px;
        border-radius: 6px;
        text-decoration: none;
        display: inline-block;
        margin: 16px 0;
      ">Se connecter</a>
      <p>Bienvenue sur la plateforme !</p>
    `,
  });
};

export const sendPasswordResetEmail = async (
  email: string,
  nom: string,
  plainToken: string
): Promise<void> => {
  const link = `${env.APP_URL}/auth/set-password?token=${plainToken}`;

  await transporter.sendMail({
    from: env.MAIL_FROM,
    to: email,
    subject: 'Réinitialisation de mot de passe — Plateforme Hajj',
    html: `
      <h2>Bonjour ${nom}</h2>
      <p>Une demande de réinitialisation de mot de passe a été faite pour votre compte.</p>
      <a href="${link}" style="
        background: #2563eb;
        color: white;
        padding: 12px 24px;
        border-radius: 6px;
        text-decoration: none;
        display: inline-block;
        margin: 16px 0;
      ">Réinitialiser mon mot de passe</a>
      <p>Ce lien expire dans 1 heure.</p>
      <p>Si vous n'avez pas fait cette demande, ignorez cet email.</p>
    `,
  });
};