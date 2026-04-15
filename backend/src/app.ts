import express from "express";
import cors from "cors";
import authRouter from "./modules/auth/auth.router";
import agencesRouter from "./modules/agences/agences.router";
import adminRouter from './modules/admin/admin.router';

import pelerinsRouter from './modules/agences/pelerin/pelerins.router';
import groupesRouter from './modules/agences/groupes/groupes.router';

import guideRouter from './modules/agences/guide/guide.router';

import guideParcoursRoutes from './modules/agences/guide/parcours/parcours.router';
import pelerinParcoursRoutes from './modules/agences/pelerin/parcours/parcours.router';
import familleParcoursRoutes from './modules/agences/famille/parcours/parcours.router';
const app=express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get("/health", (req, res) => {
  res.json({ status: 'ok' });
});
app.use('/auth', authRouter);
app.use('/agences', agencesRouter);
app.use('/admin', adminRouter);

app.use('/agence/pelerins', pelerinsRouter);
app.use('/agence/groupes', groupesRouter);

app.use('/agence/guides', guideRouter);
app.use('/agence', agencesRouter);
app.use('/guide', guideParcoursRoutes);
app.use('/pelerin', pelerinParcoursRoutes);
app.use('/famille', familleParcoursRoutes);

export default app;
