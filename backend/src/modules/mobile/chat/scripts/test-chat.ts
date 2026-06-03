import dotenv from 'dotenv';
import fs from 'fs/promises';
import path from 'path';

dotenv.config();

type SupportedLanguage = 'ar' | 'fr' | 'en';
type TokenRole = 'pelerin' | 'famille' | 'guide';
type TestStatus = 'PASS' | 'FAIL' | 'ERROR';

interface TestCase {
  name: string;
  message: string;
  tokenRole: TokenRole;
  language: SupportedLanguage;
  expectedBehavior: string;
  expectedKeywords?: string[];
  blockedPhrases?: string[];
  shouldBeBlocked?: boolean;
}

interface ChatResponse {
  answer?: string;
  usedFallback?: boolean;
  error?: string;
}

interface TestResult {
  name: string;
  role: TokenRole;
  language: SupportedLanguage;
  question: string;
  expectedBehavior: string;
  status: TestStatus;
  httpStatus: number | string;
  durationMs: number;
  providerLabel: string;
  keywordsFound: string;
  answer: string;
  answerPreview: string;
}

const BASE_URL =
  process.env.CHAT_URL ?? 'http://localhost:3000/mobile/chat/message';

const PRIMARY_PROVIDER = process.env.CHAT_PRIMARY_PROVIDER ?? 'primary';
const FALLBACK_PROVIDER = process.env.CHAT_FALLBACK_PROVIDER ?? 'fallback';

const TOKENS: Record<TokenRole, string> = {
  pelerin: process.env.PELERIN_TOKEN ?? '',
  famille: process.env.FAMILLE_TOKEN ?? '',
  guide: process.env.GUIDE_TOKEN ?? '',
};

const DEFAULT_BLOCKED_PHRASES = [
  'لا أملك',
  'غير متوفرة',
  'لا توجد معلومات',
  'لا تتوفر معلومات',
  "je n'ai pas",
  'pas assez',
  'pas disponible',
  'not have enough',
  'not available',
];

const testCases: TestCase[] = [
  {
    name: 'AR - شروط صحة الطواف',
    message: 'ما هي شروط صحة الطواف؟',
    tokenRole: 'guide',
    language: 'ar',
    expectedBehavior: 'Citer des conditions concrètes de validité du tawaf.',
    expectedKeywords: ['الطهارة', 'ستر العورة', 'سبعة', 'يساره'],
  },
  {
    name: 'AR - رمي الجمرات',
    message: 'كيف يتم رمي الجمرات؟',
    tokenRole: 'pelerin',
    language: 'ar',
    expectedBehavior: 'Expliquer le rite sans inventer de détails absents.',
    expectedKeywords: ['الجمرات', 'رمي'],
  },
  {
    name: 'AR - استعداد الحاج',
    message: 'ما هي الأمور التي يجب على الحاج الاستعداد بها قبل القيام بالعبادة؟',
    tokenRole: 'pelerin',
    language: 'ar',
    expectedBehavior: 'Donner une réponse structurée sur la préparation.',
    expectedKeywords: ['الوثائق', 'الهاتف', 'المجموعة'],
  },
  {
    name: 'AR - معلومات غير متوفرة',
    message: 'كم تبلغ تكلفة رسوم تأشيرة العمرة هذا العام؟',
    tokenRole: 'pelerin',
    language: 'ar',
    expectedBehavior: 'Refuser prudemment au lieu de donner un prix inventé.',
    shouldBeBlocked: true,
  },
  {
    name: 'FR - Étapes Omra',
    message: 'Quelles sont les étapes de la Omra ?',
    tokenRole: 'pelerin',
    language: 'fr',
    expectedBehavior: "Lister les étapes essentielles de l'Omra.",
    expectedKeywords: ['ihram', 'tawaf', "sa'i"],
  },
  {
    name: 'FR - Santé chaleur',
    message: 'Que faire si un pèlerin se sent épuisé par la chaleur ?',
    tokenRole: 'famille',
    language: 'fr',
    expectedBehavior: 'Répondre avec des conseils santé prudents.',
    expectedKeywords: ['chaleur', 'hydrat', 'aide'],
  },
  {
    name: 'FR - Hors sujet',
    message: 'Quel est le meilleur restaurant à Paris ?',
    tokenRole: 'pelerin',
    language: 'fr',
    expectedBehavior: 'Refuser car la question est hors base de connaissances.',
    shouldBeBlocked: true,
  },
];

function tokenStatus(token: string): string {
  return token ? `set (${token.length} chars)` : 'missing';
}

function requireToken(role: TokenRole): string {
  const token = TOKENS[role];

  if (!token) {
    throw new Error(
      `Missing token for role "${role}". Set ${role.toUpperCase()}_TOKEN in the environment.`
    );
  }

  return token;
}

function normalize(value: string): string {
  return value
    .toLowerCase()
    .replace(/[\u064B-\u065F\u0670]/g, '')
    .replace(/[أإآٱ]/g, 'ا')
    .replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه')
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '');
}

function compactAnswer(value: string, maxLength = 180): string {
  const compacted = value.trim().replace(/\s+/g, ' ');
  return compacted.length > maxLength
    ? `${compacted.slice(0, maxLength).trim()}...`
    : compacted;
}

function providerLabel(usedFallback?: boolean): string {
  if (usedFallback) return `Fallback (${FALLBACK_PROVIDER || 'none'})`;
  return `Primary (${PRIMARY_PROVIDER})`;
}

function hasBlockedAnswer(answer: string, phrases: string[] = DEFAULT_BLOCKED_PHRASES): boolean {
  const normalizedAnswer = normalize(answer);
  return phrases.some((phrase) => normalizedAnswer.includes(normalize(phrase)));
}

function evaluateAnswer(testCase: TestCase, httpOk: boolean, answer: string): {
  passed: boolean;
  keywordsFound: string[];
} {
  const expectedKeywords = testCase.expectedKeywords ?? [];
  const normalizedAnswer = normalize(answer);
  const keywordsFound = expectedKeywords.filter((keyword) =>
    normalizedAnswer.includes(normalize(keyword))
  );

  if (!httpOk || answer.trim().length < 10) {
    return { passed: false, keywordsFound };
  }

  if (testCase.shouldBeBlocked) {
    return {
      passed: hasBlockedAnswer(answer, testCase.blockedPhrases),
      keywordsFound,
    };
  }

  return {
    passed: expectedKeywords.length === 0 || keywordsFound.length > 0,
    keywordsFound,
  };
}

async function runTest(testCase: TestCase): Promise<TestResult> {
  const start = Date.now();

  try {
    const token = requireToken(testCase.tokenRole);
    const payload = {
      message: testCase.message,
      history: [],
      language: testCase.language,
    };

    const res = await fetch(BASE_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(payload),
    });

    const durationMs = Date.now() - start;
    const data = (await res.json()) as ChatResponse;
    const answer = data.answer ?? data.error ?? '';
    const evaluation = evaluateAnswer(testCase, res.ok, answer);

    return {
      name: testCase.name,
      role: testCase.tokenRole,
      language: testCase.language,
      question: testCase.message,
      expectedBehavior: testCase.expectedBehavior,
      status: evaluation.passed ? 'PASS' : 'FAIL',
      httpStatus: res.status,
      durationMs,
      providerLabel: providerLabel(data.usedFallback),
      keywordsFound: evaluation.keywordsFound.join(', ') || '-',
      answer,
      answerPreview: compactAnswer(answer || 'No answer returned'),
    };
  } catch (err) {
    const answer = err instanceof Error ? err.message : String(err);

    return {
      name: testCase.name,
      role: testCase.tokenRole,
      language: testCase.language,
      question: testCase.message,
      expectedBehavior: testCase.expectedBehavior,
      status: 'ERROR',
      httpStatus: '-',
      durationMs: Date.now() - start,
      providerLabel: '-',
      keywordsFound: '-',
      answer,
      answerPreview: compactAnswer(answer),
    };
  }
}

function escapeHtml(value: unknown): string {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function languageLabel(language: SupportedLanguage): string {
  switch (language) {
    case 'ar':
      return 'Arabe';
    case 'fr':
      return 'Français';
    case 'en':
      return 'Anglais';
  }
}

function roleLabel(role: TokenRole): string {
  switch (role) {
    case 'pelerin':
      return 'Pèlerin';
    case 'famille':
      return 'Famille';
    case 'guide':
      return 'Guide';
  }
}

async function writeHtmlReport(results: TestResult[]): Promise<string> {
  const reportPath = path.resolve(process.cwd(), 'chatbot-test-report.html');
  const passed = results.filter((r) => r.status === 'PASS').length;
  const avgDuration = Math.round(
    results.reduce((sum, r) => sum + r.durationMs, 0) / results.length
  );
  const fallbackCount = results.filter((r) =>
    r.providerLabel.startsWith('Fallback')
  ).length;

  const cards = results.map((r, index) => {
    const isArabic = r.language === 'ar';
    const dir = isArabic ? 'rtl' : 'ltr';
    const statusClass = r.status.toLowerCase();
    const providerClass = r.providerLabel.startsWith('Primary') ? 'primary' : 'fallback';
    const statusIcon = r.status === 'PASS' ? '✓' : r.status === 'FAIL' ? '✗' : '!';

    return `
    <div class="card ${statusClass}">
      <div class="card-header">
        <div class="card-left">
          <span class="card-index">${index + 1}</span>
          <div class="card-title-group">
            <span class="card-name">${escapeHtml(r.name)}</span>
            <span class="card-behavior">${escapeHtml(r.expectedBehavior)}</span>
          </div>
        </div>
        <div class="card-right">
          <span class="badge">${escapeHtml(roleLabel(r.role))}</span>
          <span class="badge">${escapeHtml(languageLabel(r.language))}</span>
          <span class="engine ${providerClass}">${escapeHtml(r.providerLabel)}</span>
          <span class="duration">${r.durationMs}ms</span>
          <span class="status ${statusClass}">${statusIcon} ${r.status}</span>
        </div>
      </div>
      <div class="card-body">
        <div class="field">
          <span class="field-label">Question</span>
          <span class="field-value" dir="${dir}">${escapeHtml(r.question)}</span>
        </div>
        ${r.keywordsFound !== '-' ? `
        <div class="field">
          <span class="field-label">Mots-clés trouvés</span>
          <span class="field-value keywords">${escapeHtml(r.keywordsFound)}</span>
        </div>` : ''}
        <div class="field">
          <span class="field-label">Réponse générée</span>
          <span class="field-value answer" dir="${dir}">${escapeHtml(r.answer)}</span>
        </div>
      </div>
    </div>`;
  }).join('');

  const html = `<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <title>Matrice d'évaluation du chatbot RAG</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      padding: 32px;
      background: #f8fafc;
      color: #111827;
      font-family: "Segoe UI", Tahoma, Arial, sans-serif;
    }
    header {
      border-bottom: 2px solid #111827;
      padding-bottom: 14px;
      margin-bottom: 24px;
    }
    h1 {
      font-size: 20px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.02em;
      margin-bottom: 6px;
    }
    .meta {
      display: flex;
      justify-content: space-between;
      color: #64748b;
      font-size: 12px;
      font-family: Consolas, monospace;
    }
    .metrics {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 10px;
      margin-bottom: 24px;
    }
    .metric {
      background: #fff;
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      padding: 14px;
      text-align: center;
    }
    .metric-label {
      color: #64748b;
      font-size: 10px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 4px;
    }
    .metric-value {
      font-size: 24px;
      font-weight: 700;
    }
    .metric-value.success { color: #047857; }
    .cards { display: flex; flex-direction: column; gap: 12px; }
    .card {
      background: #fff;
      border: 1px solid #e5e7eb;
      border-radius: 10px;
      overflow: hidden;
    }
    .card.fail { border-left: 4px solid #f97316; }
    .card.error { border-left: 4px solid #ef4444; }
    .card.pass { border-left: 4px solid #10b981; }
    .card-header {
      display: flex;
      align-items: flex-start;
      justify-content: space-between;
      padding: 12px 16px;
      background: #f8fafc;
      border-bottom: 1px solid #e5e7eb;
      gap: 12px;
    }
    .card-left {
      display: flex;
      align-items: flex-start;
      gap: 10px;
    }
    .card-index {
      background: #111827;
      color: #fff;
      font-size: 11px;
      font-weight: 700;
      width: 22px;
      height: 22px;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      margin-top: 2px;
    }
    .card-title-group { display: flex; flex-direction: column; gap: 2px; }
    .card-name { font-size: 13px; font-weight: 600; }
    .card-behavior { font-size: 11px; color: #64748b; }
    .card-right {
      display: flex;
      align-items: center;
      flex-wrap: wrap;
      gap: 6px;
      justify-content: flex-end;
      flex-shrink: 0;
    }
    .card-body { padding: 14px 16px; display: flex; flex-direction: column; gap: 10px; }
    .field { display: flex; flex-direction: column; gap: 3px; }
    .field-label {
      font-size: 10px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: #94a3b8;
    }
    .field-value {
      font-size: 13px;
      line-height: 1.55;
      color: #1e293b;
      white-space: pre-wrap;
    }
    .field-value.keywords {
      color: #047857;
      font-weight: 500;
    }
    .field-value.answer {
      background: #f8fafc;
      border: 1px solid #e5e7eb;
      border-radius: 6px;
      padding: 10px 12px;
    }
    [dir="rtl"] {
      text-align: right;
      font-family: Tahoma, "Segoe UI", Arial, sans-serif;
      font-size: 13.5px;
      line-height: 1.7;
    }
    .badge {
      display: inline-block;
      background: #eef2ff;
      color: #3730a3;
      font-size: 11px;
      font-weight: 600;
      padding: 2px 8px;
      border-radius: 999px;
    }
    .engine {
      display: inline-block;
      font-size: 11px;
      font-weight: 600;
      padding: 2px 8px;
      border-radius: 999px;
    }
    .engine.primary { background: #ecfdf5; color: #065f46; }
    .engine.fallback { background: #fff7ed; color: #9a3412; }
    .duration { font-size: 11px; color: #94a3b8; }
    .status {
      display: inline-block;
      font-size: 11px;
      font-weight: 700;
      padding: 3px 10px;
      border-radius: 999px;
    }
    .status.pass { background: #d1fae5; color: #065f46; }
    .status.fail { background: #fed7aa; color: #9a3412; }
    .status.error { background: #fee2e2; color: #991b1b; }
    @media print {
      body { background: #fff; padding: 16px; }
      .card { break-inside: avoid; }
    }
  </style>
</head>
<body>
  <header>
    <h1>Annexe — Matrice d'évaluation technique du chatbot RAG</h1>
    <div class="meta">
      <span>Généré le : ${new Date().toLocaleDateString('fr-FR')}</span>
      <span>Backend : ${escapeHtml(BASE_URL)}</span>
    </div>
  </header>

  <section class="metrics">
    <div class="metric">
      <div class="metric-label">Taux de réussite</div>
      <div class="metric-value success">${Math.round((passed / results.length) * 100)}%</div>
    </div>
    <div class="metric">
      <div class="metric-label">Cas exécutés</div>
      <div class="metric-value">${results.length}</div>
    </div>
    <div class="metric">
      <div class="metric-label">Latence moyenne</div>
      <div class="metric-value">${avgDuration}ms</div>
    </div>
    <div class="metric">
      <div class="metric-label">Fallback utilisé</div>
      <div class="metric-value">${fallbackCount}/${results.length}</div>
    </div>
  </section>

  <div class="cards">${cards}</div>
</body>
</html>`;

  await fs.writeFile(reportPath, html, 'utf8');
  return reportPath;
}

async function writeVerticalHtmlReport(results: TestResult[]): Promise<string> {
  const reportPath = path.resolve(process.cwd(), 'chatbot-test-report.html');
  const rows = results
    .map((r, index) => {
      const isArabic = r.language === 'ar';
      const dir = isArabic ? 'rtl' : 'ltr';

      return `
      <tr>
        <td class="scenario">${escapeHtml(`${index + 1}. ${r.name}`)}</td>
        <td>${escapeHtml(roleLabel(r.role))}</td>
        <td>${escapeHtml(languageLabel(r.language))}</td>
        <td class="question" dir="${dir}">${escapeHtml(r.question)}</td>
        <td class="answer" dir="${dir}">${escapeHtml(r.answer)}</td>
      </tr>`;
    })
    .join('');

  const html = `<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <title>Evaluation du chatbot RAG</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      padding: 24px;
      background: #fff;
      color: #002b25;
      font-family: "Segoe UI", Tahoma, Arial, sans-serif;
    }
    .table-wrap {
      width: min(1180px, 100%);
      margin: 0 auto;
      border: 1px solid #dfe7e3;
      overflow: hidden;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      table-layout: fixed;
    }
    thead th {
      background: #edf5f1;
      color: #003d34;
      padding: 13px 12px;
      text-align: left;
      font-size: 13px;
      font-weight: 900;
      text-transform: uppercase;
      letter-spacing: 0.02em;
    }
    tbody tr {
      border-bottom: 1px solid #dfe7e3;
    }
    td {
      padding: 15px 12px;
      vertical-align: top;
      font-size: 14px;
      line-height: 1.55;
      white-space: pre-wrap;
      overflow-wrap: anywhere;
    }
    th:nth-child(1), td:nth-child(1) { width: 16%; }
    th:nth-child(2), td:nth-child(2) { width: 9.5%; }
    th:nth-child(3), td:nth-child(3) { width: 9.5%; }
    th:nth-child(4), td:nth-child(4) { width: 21.5%; }
    th:nth-child(5), td:nth-child(5) { width: 43.5%; }
    .scenario {
      font-weight: 500;
    }
    .question {
      color: #001f1a;
    }
    .answer {
      color: #001f1a;
    }
    [dir="rtl"] {
      text-align: right;
      font-family: Tahoma, "Segoe UI", Arial, sans-serif;
      font-size: 15px;
      line-height: 1.75;
    }
  </style>
</head>
<body>
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Scenario</th>
          <th>Role</th>
          <th>Langue</th>
          <th>Question</th>
          <th>Reponse generee</th>
        </tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>
  </div>
</body>
</html>`;

  await fs.writeFile(reportPath, html, 'utf8');
  return reportPath;
}

async function main(): Promise<void> {
  console.log('');
  console.log('Chatbot RAG Test Matrix');
  console.log('='.repeat(100));
  console.log(`Endpoint: ${BASE_URL}`);
  console.log(`Primary provider: ${PRIMARY_PROVIDER}`);
  console.log(`Fallback provider: ${FALLBACK_PROVIDER || 'none'}`);
  console.log(
    `Tokens: pelerin=${tokenStatus(TOKENS.pelerin)}, famille=${tokenStatus(
      TOKENS.famille
    )}, guide=${tokenStatus(TOKENS.guide)}`
  );
  console.log('');

  const results: TestResult[] = [];

  for (const testCase of testCases) {
    process.stdout.write(`Testing: ${testCase.name}... `);
    const result = await runTest(testCase);
    console.log(result.status);
    results.push(result);
  }

  console.log('');
  console.log('='.repeat(100));
  console.log('Résultats');
  console.log('');
  console.log(
    'Scénario'.padEnd(34),
    'Statut'.padEnd(8),
    'HTTP'.padEnd(6),
    'Durée'.padEnd(10),
    'Provider'.padEnd(22),
    'Aperçu réponse'
  );
  console.log('-'.repeat(140));

  for (const result of results) {
    console.log(
      result.name.padEnd(34),
      result.status.padEnd(8),
      String(result.httpStatus).padEnd(6),
      `${result.durationMs}ms`.padEnd(10),
      result.providerLabel.padEnd(22),
      result.answerPreview
    );
  }

  const passed = results.filter((result) => result.status === 'PASS').length;
  const reportPath = await writeVerticalHtmlReport(results);

  console.log('');
  console.log(`${passed}/${results.length} tests passés`);
  console.log(`Rapport HTML généré: ${reportPath}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
