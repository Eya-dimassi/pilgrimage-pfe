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
  const link = `${env.APP_URL}/activate-account?token=${plainToken}`;

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
       
      <p><strong>Important :</strong></p>
      <ul>
        <li>Ce lien est valable pendant <strong>7 jours</strong></li>
        <li>Vous devrez définir un mot de passe de minimum 8 caractères</li>
        <li>Après activation, vous pourrez vous connecter</li>
      </ul>
      <hr>
      <p style="color: #666; font-size: 12px;">SmartHajj - Gestion intelligente du Hajj & Umrah</p>
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
export const sendRejectionEmail = async (email: string, nomAgence: string) => {
  await transporter.sendMail({
    from: `"SmartHajj" <${env.MAIL_FROM}>`,
    to: email,
    subject: 'Votre demande d\'inscription a été refusée',
    html: `
      <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #c0392b;">Demande refusée</h2>
        <p>Bonjour,</p>
        <p>Nous avons examiné la demande d'inscription de l'agence <strong>${nomAgence}</strong> et nous ne sommes malheureusement pas en mesure de l'approuver pour le moment.</p>
        <p>Si vous pensez qu'il s'agit d'une erreur ou souhaitez plus d'informations, veuillez nous contacter.</p>
        <p style="color: #888; font-size: 13px; margin-top: 32px;">L'équipe SmartHajj</p>
      </div>
    `,
  })
}

export const sendSuspensionEmail = async (email: string, nomAgence: string) => {
  await transporter.sendMail({
    from: `"SmartHajj" <${env.MAIL_FROM}>`,
    to: email,
    subject: 'Votre compte a été suspendu',
    html: `
      <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #e67e22;">Compte suspendu</h2>
        <p>Bonjour,</p>
        <p>Le compte de l'agence <strong>${nomAgence}</strong> a été suspendu par notre équipe d'administration.</p>
        <p>Vous ne pouvez plus accéder à la plateforme SmartHajj jusqu'à nouvel ordre.</p>
        <p>Pour toute question, veuillez nous contacter directement.</p>
        <p style="color: #888; font-size: 13px; margin-top: 32px;">L'équipe SmartHajj</p>
      </div>
    `,
  })
}
/* ⭐ AJOUTER CETTE FONCTION
export const sendGuideActivationEmail = async (
  email: string,
  prenom: string,
  nom: string,
  nomAgence: string,
  plainToken: string
): Promise<void> => {
  const link = `${env.APP_URL}/activate-account?token=${plainToken}`;

  await transporter.sendMail({
    from: env.MAIL_FROM,
    to: email,
    subject: `Activez votre compte Guide — ${nomAgence}`,
    html: `
      <h2>Bienvenue ${prenom} ${nom} !</h2>
      <p>L'agence <strong>${nomAgence}</strong> vous a créé un compte Guide sur la plateforme Hajj/Umrah.</p>
      
      <p><strong>Votre email de connexion :</strong> ${email}</p>
      
      <p>Pour activer votre compte et définir votre mot de passe, cliquez sur le bouton ci-dessous :</p>
      
      <a href="${link}" style="
        background: #2E7D32;
        color: white;
        padding: 12px 24px;
        border-radius: 6px;
        text-decoration: none;
        display: inline-block;
        margin: 16px 0;
      ">Activer mon compte</a>
      
      <p><strong>Important :</strong></p>
      <ul>
        <li>Ce lien est valable pendant <strong>7 jours</strong></li>
        <li>Vous devrez définir un mot de passe de minimum 8 caractères</li>
        <li>Après activation, vous pourrez vous connecter</li>
      </ul>
      
      <p>Si vous n'êtes pas à l'origine de cette demande, veuillez contacter l'agence ${nomAgence}.</p>
      
      <hr>
      <p style="color: #666; font-size: 12px;">SmartHajj - Gestion intelligente du Hajj & Umrah</p>
    `,
  });
};*/