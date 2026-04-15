import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import prisma from '../../config/prisma';
import { env } from '../../config/env';
import { Role,StatutAgence} from '../../../generated/prisma/enums';
import { createPasswordToken, verifyPasswordToken, consumePasswordToken, hashToken } from '../../utils/token.utils';
import { sendPasswordResetEmail } from '../../utils/mailer.utils';



export const login =async(email: string, motDePasse: string) => {
  //sql query
  const utilisateur = await prisma.utilisateur.findUnique({
    where: { email },
    include: {
      agence: { select: { id: true, status: true } },
      guide: { select: { agenceId: true } },
      pelerin: { select: { agenceId: true } },
      famille: {
        include: {
          associations: {
            where: { actif: true },
            take: 1,
            include: { pelerin: { select: { agenceId: true } } },
          },
        },
      },
    },
  });


if (!utilisateur) {
  throw new Error('Email ou mot de passe incorrect');
}

// password not set yet
  if (!utilisateur.motDePasse) {
    throw new Error('Compte non activé');
  }

//agence status check 
  if (utilisateur.role === 'AGENCE' && utilisateur.agence) {
    if (utilisateur.agence.status === 'PENDING') {
      throw new Error('Votre compte est en attente de validation');
    }
    if (utilisateur.agence.status === 'REJECTED') {
      throw new Error('Votre demande a été refusée');
    }
    if (utilisateur.agence.status === 'SUSPENDED') {
      throw new Error('Votre compte a été suspendu');
    }
  }
  //user not found or inactive
  if (!utilisateur.actif) {
    throw new Error('Compte inactif');
  }
  

  //password check
  const passwordMatch =await bcrypt.compare(motDePasse, utilisateur.motDePasse);
  if (!passwordMatch) {
    throw new Error('Email ou mot de passe incorrect');
  }


  let agenceId: string | null =null;

  if (utilisateur.role === 'AGENCE' && utilisateur.agence) {
    agenceId = utilisateur.agence.id;
  } else if (utilisateur.role === 'GUIDE' && utilisateur.guide) {
    agenceId = utilisateur.guide.agenceId;
  } else if (utilisateur.role === 'PELERIN' && utilisateur.pelerin) {
    agenceId = utilisateur.pelerin.agenceId;
  }else if (utilisateur.role === 'FAMILLE' && utilisateur.famille) {
    agenceId = utilisateur.famille.associations?.[0]?.pelerin?.agenceId ?? null;
  }


  const accessToken = jwt.sign(
    {
      sub: utilisateur.id,
      email: utilisateur.email,
      role: utilisateur.role,
      agenceId,
    },
    env.JWT_SECRET,
      {expiresIn: '15m'}
  );

  const refreshToken = uuidv4();
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate()+30);

  await prisma.refreshToken.create({
    data: {
      token: refreshToken,
      utilisateurId: utilisateur.id,
      expiresAt,
    },
  });

  return {
    accessToken,
    refreshToken,
    utilisateur: {
      id: utilisateur.id,
      nom: utilisateur.nom,
      prenom: utilisateur.prenom,
      email: utilisateur.email,
      role: utilisateur.role,
      agenceId,
    },
  };
};


export const signup = async (data: {
  nomAgence: string;
  email: string;
  motDePasse: string;
  telephone?: string;
  adresse?: string;
  siteWeb?: string;
}) => {
  // check email not already taken
  const exist = await prisma.utilisateur.findUnique({
    where: { email: data.email },
  });
  if (exist) throw new Error('Un compte avec cet email existe déjà');

  const hash = await bcrypt.hash(data.motDePasse, 10);

  const utilisateur = await prisma.utilisateur.create({
    data: {
      email: data.email,
      motDePasse: hash,
      nom: data.nomAgence,
      prenom: '-',
      telephone: data.telephone,
      role: Role.AGENCE,
      actif: false,          // can't log in until approved
      agence: {
        create: {
          nomAgence: data.nomAgence,
          adresse: data.adresse,
          siteWeb: data.siteWeb,
          status: StatutAgence.PENDING, // admin must approve
        },
      },
    },
    include: { agence: true },
  });

  return {
    message: 'Demande envoyée, en attente de validation par l\'administrateur',
    agenceId: utilisateur.agence!.id,
  };
};

export const logout = async (refreshToken: string) => {
  await prisma.refreshToken.deleteMany({ where: { token: refreshToken } });
};




export const refresh = async (refreshToken: string) => {
  const tokenRecord = await prisma.refreshToken.findUnique({
    where: { token: refreshToken },
    include: {
      utilisateur: {
        include: {
          agence:  { select: { id: true } },
          guide:   { select: { agenceId: true } },
          pelerin: { select: { agenceId: true } },
          famille: {
            include: {
              associations: {
                where: { actif: true },
                take: 1,
                include: { pelerin: { select: { agenceId: true } } },
              },
            },
          },
        }
      }
    },
  })

  if (!tokenRecord) throw new Error('Refresh token invalide')

  if (tokenRecord.expiresAt < new Date()) {
    await prisma.refreshToken.delete({ where: { token: refreshToken } })
    throw new Error('Refresh token expiré')
  }

  const u = tokenRecord.utilisateur

  let agenceId: string | null = null
  if (u.role === 'AGENCE')        agenceId = u.agence?.id        ?? null
  else if (u.role === 'GUIDE')    agenceId = u.guide?.agenceId   ?? null
  else if (u.role === 'PELERIN')  agenceId = u.pelerin?.agenceId ?? null
  else if (u.role === 'FAMILLE')  agenceId = u.famille?.associations?.[0]?.pelerin?.agenceId ?? null

  const accessToken = jwt.sign(
    { sub: u.id, email: u.email, role: u.role, agenceId },
    env.JWT_SECRET,
    { expiresIn: '15m' }
  )

  const newRefreshToken = uuidv4()
  const expiresAt = new Date()
  expiresAt.setDate(expiresAt.getDate() + 30)

  await prisma.refreshToken.update({
    where: { token: refreshToken },
    data: { token: newRefreshToken, expiresAt },
  })

  return { accessToken, refreshToken: newRefreshToken }
}

export const getMe =async(userId: string) => {
  const utilisateur = await prisma.utilisateur.findUnique({
    where: {id:userId},
    include: {
      agence: { select: { id: true } },
      guide: {
        select: {
          agenceId: true,
          specialite: true,
        },
      },
      pelerin: {
        select: {
          agenceId: true,
          codeUnique: true,
          dateNaissance: true,
          nationalite: true,
          numeroPasseport: true,
          photoUrl: true,
          groupes: {
            where: {
              actif: true,
            },
            orderBy: {
              dateDebut: 'desc',
            },
            take: 1,
            select: {
              groupe: {
                select: {
                  nom: true,
                },
              },
            },
          },
        },
      },
      famille: {
        include: {
          associations: {
            where: { actif: true },
            take: 1,
            include: { pelerin: { select: { agenceId: true } } },
          },
        },
      },
    },
  });

  if (!utilisateur) {
    return null;
  }

  let agenceId: string | null = null;

  if (utilisateur.role === 'AGENCE' && utilisateur.agence) {
    agenceId = utilisateur.agence.id;
  } else if (utilisateur.role === 'GUIDE' && utilisateur.guide) {
    agenceId = utilisateur.guide.agenceId;
  } else if (utilisateur.role === 'PELERIN' && utilisateur.pelerin) {
    agenceId = utilisateur.pelerin.agenceId;
  } else if (utilisateur.role === 'FAMILLE' && utilisateur.famille) {
    agenceId = utilisateur.famille.associations?.[0]?.pelerin?.agenceId ?? null;
  }

  return {
    id: utilisateur.id,
    nom: utilisateur.nom,
    prenom: utilisateur.prenom,
    email: utilisateur.email,
    role: utilisateur.role,
    telephone: utilisateur.telephone,
    agenceId,
    lienParente: utilisateur.famille?.lienParente ?? null,
    specialite: utilisateur.guide?.specialite ?? null,
    codeUnique: utilisateur.pelerin?.codeUnique ?? null,
    dateNaissance: utilisateur.pelerin?.dateNaissance ?? null,
    nationalite: utilisateur.pelerin?.nationalite ?? null,
    numeroPasseport: utilisateur.pelerin?.numeroPasseport ?? null,
    photoUrl: utilisateur.pelerin?.photoUrl ?? null,
    groupeNom: utilisateur.pelerin?.groupes[0]?.groupe.nom ?? null,
  };
};



// ── FORGOT PASSWORD ────────────────────────────────────────
export const forgotPassword = async (email: string) => {
  const utilisateur = await prisma.utilisateur.findUnique({ where: { email } });

  // always return same message — don't reveal if email exists
  if (!utilisateur) {
    return { message: 'Si cet email existe, un lien de réinitialisation a été envoyé' };
  }

  const plainToken = await createPasswordToken(utilisateur.id, 'RESET_PASSWORD');
  await sendPasswordResetEmail(email, utilisateur.nom, plainToken);

  return { message: 'Si cet email existe, un lien de réinitialisation a été envoyé' };
};

// ── SET PASSWORD ───────────────────────────────────────────
export const setPassword = async (plainToken: string, newPassword: string) => {
  const record = await verifyPasswordToken(plainToken);

  if (newPassword.length < 8) {
    throw new Error('Mot de passe trop court (8 caractères minimum)');
  }

  const hash = await bcrypt.hash(newPassword, 10);

  await prisma.utilisateur.update({
    where: { id: record.utilisateurId },
    data: { motDePasse: hash, actif: true },
  });

  await consumePasswordToken(record.tokenHash);

  return { message: 'Mot de passe défini avec succès' };
};
// ⭐ AJOUTER CETTE FONCTION
export const verifyActivationToken = async (token: string) => {
  // Vérifier et décoder le token
  const record = await verifyPasswordToken(token);
  
  // Récupérer les infos de l'utilisateur
  const utilisateur = await prisma.utilisateur.findUnique({
    where: { id: record.utilisateurId },
    select: {
      id: true,
      email: true,
      nom: true,
      prenom: true,
      actif: true,
      motDePasse: true
    }
  });

  if (!utilisateur) {
    throw new Error('Utilisateur introuvable');
  }

  // Si déjà activé, erreur
  if (utilisateur.actif && utilisateur.motDePasse) {
    throw new Error('Ce compte est déjà activé');
  }

  return {
    email: utilisateur.email,
    nom: `${utilisateur.prenom} ${utilisateur.nom}`
  };
};
export const familySignup = async (data: {
  nom: string;
  prenom: string;
  email: string;
  motDePasse: string;
  codeUnique: string;
  telephone?: string;
  lienParente?: string;
}) => {
  const normalizedEmail = data.email.trim().toLowerCase();
  const normalizedCode = data.codeUnique.trim();

  if (data.motDePasse.length < 8) {
    throw new Error('Mot de passe trop court (8 caracteres minimum)');
  }

  const existingUser = await prisma.utilisateur.findUnique({
    where: { email: normalizedEmail },
  });

  if (existingUser) {
    throw new Error('Un compte avec cet email existe deja');
  }

  const pelerin = await prisma.pelerin.findUnique({
    where: { codeUnique: normalizedCode },
    include: {
      utilisateur: {
        select: {
          nom: true,
          prenom: true,
        },
      },
    },
  });

  if (!pelerin) {
    throw new Error('Code unique pelerin introuvable');
  }

  const hash = await bcrypt.hash(data.motDePasse, 10);

  const famille = await prisma.famille.create({
    data: {
      lienParente: data.lienParente?.trim() || null,
      agence: {
        connect: {
          id: pelerin.agenceId,
        },
      },
      utilisateur: {
        create: {
          email: normalizedEmail,
          motDePasse: hash,
          nom: data.nom.trim(),
          prenom: data.prenom.trim(),
          telephone: data.telephone?.trim() || null,
          role: Role.FAMILLE,
          actif: true,
        },
      },
      associations: {
        create: {
          pelerinId: pelerin.id,
        },
      },
    },
    include: {
      utilisateur: {
        select: {
          id: true,
          email: true,
          nom: true,
          prenom: true,
        },
      },
      associations: {
        select: {
          pelerinId: true,
        },
      },
    },
  });

  return {
    message: 'Compte famille cree avec succes. Vous pouvez maintenant vous connecter.',
    familleId: famille.id,
    utilisateurId: famille.utilisateur.id,
    agenceId: pelerin.agenceId,
    pelerin: {
      id: pelerin.id,
      codeUnique: pelerin.codeUnique,
      nom: pelerin.utilisateur.nom,
      prenom: pelerin.utilisateur.prenom,
    },
  };
};

export const addFamilyAssociation = async (userId: string, codeUnique: string) => {
  const normalizedCode = codeUnique.trim();
  if (!normalizedCode) {
    throw new Error('Code unique requis');
  }

  const utilisateur = await prisma.utilisateur.findUnique({
    where: { id: userId },
    include: {
      famille: {
        include: {
          associations: {
            where: { actif: true },
            select: {
              pelerinId: true,
            },
          },
        },
      },
    },
  });

  if (!utilisateur || utilisateur.role !== 'FAMILLE' || !utilisateur.famille) {
    throw new Error('Compte famille introuvable');
  }

  const pelerin = await prisma.pelerin.findUnique({
    where: { codeUnique: normalizedCode },
    include: {
      utilisateur: {
        select: {
          nom: true,
          prenom: true,
        },
      },
    },
  });

  if (!pelerin) {
    throw new Error('Aucun pelerin correspondant a ce code unique');
  }

  if (pelerin.agenceId !== utilisateur.famille.agenceId) {
    throw new Error('Ce pelerin n appartient pas a la meme agence');
  }

  const alreadyLinked = utilisateur.famille.associations.some(
    (association) => association.pelerinId === pelerin.id,
  );

  if (alreadyLinked) {
    throw new Error('Ce proche est deja lie a votre compte');
  }

  await prisma.famillePelerin.create({
    data: {
      familleId: utilisateur.famille.id,
      pelerinId: pelerin.id,
    },
  });

  return {
    message: 'Proche ajoute avec succes',
    pelerin: {
      id: pelerin.id,
      codeUnique: pelerin.codeUnique,
      nom: pelerin.utilisateur.nom,
      prenom: pelerin.utilisateur.prenom,
    },
  };
};

export const getFamilyAssociations = async (userId: string) => {
  const utilisateur = await prisma.utilisateur.findUnique({
    where: { id: userId },
    include: {
      famille: {
        include: {
          associations: {
            where: { actif: true },
            orderBy: { createdAt: 'desc' },
            include: {
              pelerin: {
                include: {
                  utilisateur: {
                    select: {
                      nom: true,
                      prenom: true,
                    },
                  },
                  groupes: {
                    where: { actif: true },
                    take: 1,
                    orderBy: { dateDebut: 'desc' },
                    include: {
                      groupe: {
                        select: {
                          id: true,
                          nom: true,
                          typeVoyage: true,
                          annee: true,
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  });

  if (!utilisateur || utilisateur.role !== 'FAMILLE' || !utilisateur.famille) {
    throw new Error('Compte famille introuvable');
  }

  return utilisateur.famille.associations.map((association) => ({
    id: association.id,
    pelerinId: association.pelerin.id,
    codeUnique: association.pelerin.codeUnique,
    nom: association.pelerin.utilisateur.nom,
    prenom: association.pelerin.utilisateur.prenom,
    groupe: association.pelerin.groupes[0]?.groupe ?? null,
  }));
};
export const updateMe = async (
  userId: string,
  data: {
    nom?: string;
    prenom?: string;
    email?: string;
    telephone?: string | null;
    lienParente?: string | null;
    specialite?: string | null;
    dateNaissance?: string | Date | null;
    nationalite?: string | null;
    numeroPasseport?: string | null;
    photoUrl?: string | null;
  },
) => {
  const utilisateur = await prisma.utilisateur.findUnique({
    where: { id: userId },
    include: {
      famille: {
        select: {
          id: true,
        },
      },
      guide: {
        select: {
          id: true,
        },
      },
      pelerin: {
        select: {
          id: true,
        },
      },
    },
  });

  if (!utilisateur) {
    throw new Error('Utilisateur introuvable');
  }

  const normalizedEmail = data.email?.trim().toLowerCase();
  const normalizedNom = data.nom?.trim();
  const normalizedPrenom = data.prenom?.trim();
  const normalizedTelephone = data.telephone?.trim();
  const normalizedLienParente = data.lienParente?.trim();
  const normalizedSpecialite = data.specialite?.trim();
  const normalizedNationalite = data.nationalite?.trim();
  const normalizedNumeroPasseport = data.numeroPasseport?.trim();
  const normalizedPhotoUrl = data.photoUrl?.trim();

  let normalizedDateNaissance: Date | null | undefined;
  if (data.dateNaissance !== undefined) {
    if (!data.dateNaissance) {
      normalizedDateNaissance = null;
    } else {
      const parsedDate =
        data.dateNaissance instanceof Date
          ? data.dateNaissance
          : new Date(data.dateNaissance);

      if (Number.isNaN(parsedDate.getTime())) {
        throw new Error('Date de naissance invalide');
      }

      normalizedDateNaissance = parsedDate;
    }
  }

  if (normalizedEmail) {
    const existingUser = await prisma.utilisateur.findFirst({
      where: {
        email: normalizedEmail,
        NOT: {
          id: userId,
        },
      },
      select: {
        id: true,
      },
    });

    if (existingUser) {
      throw new Error('Cet email est deja utilise');
    }
  }

  await prisma.utilisateur.update({
    where: { id: userId },
    data: {
      ...(normalizedNom ? { nom: normalizedNom } : {}),
      ...(normalizedPrenom ? { prenom: normalizedPrenom } : {}),
      ...(normalizedEmail ? { email: normalizedEmail } : {}),
      telephone:
        data.telephone !== undefined
          ? normalizedTelephone || null
          : undefined,
    },
  });

  if (utilisateur.role === 'FAMILLE' && utilisateur.famille) {
    await prisma.famille.update({
      where: { id: utilisateur.famille.id },
      data: {
        lienParente:
          data.lienParente !== undefined
            ? normalizedLienParente || null
            : undefined,
      },
    });
  }

  if (utilisateur.role === 'GUIDE' && utilisateur.guide) {
    await prisma.guide.update({
      where: { id: utilisateur.guide.id },
      data: {
        specialite:
          data.specialite !== undefined ? normalizedSpecialite || null : undefined,
      },
    });
  }

  if (utilisateur.role === 'PELERIN' && utilisateur.pelerin) {
    await prisma.pelerin.update({
      where: { id: utilisateur.pelerin.id },
      data: {
        dateNaissance:
          data.dateNaissance !== undefined ? normalizedDateNaissance : undefined,
        nationalite:
          data.nationalite !== undefined
            ? normalizedNationalite || null
            : undefined,
        numeroPasseport:
          data.numeroPasseport !== undefined
            ? normalizedNumeroPasseport || null
            : undefined,
        photoUrl:
          data.photoUrl !== undefined ? normalizedPhotoUrl || null : undefined,
      },
    });
  }

  return getMe(userId);
};
