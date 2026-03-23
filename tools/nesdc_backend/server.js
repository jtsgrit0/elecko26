const express = require('express');
const cors = require('cors');
const cheerio = require('cheerio');
const pdfParse = require('pdf-parse');

const app = express();
app.use(cors());

const BASE_URL = process.env.NESDC_BASE_URL || 'https://www.nesdc.go.kr';
const DEFAULT_PAGES = Number(process.env.NESDC_PAGES || 2);
const DEFAULT_LIMIT = Number(process.env.NESDC_LIMIT || 20);

app.get('/health', (req, res) => {
  res.json({ ok: true });
});

app.get('/polls', async (req, res) => {
  try {
    const pages = Number(req.query.pages || DEFAULT_PAGES);
    const limit = Number(req.query.limit || DEFAULT_LIMIT);
    const includeText = `${req.query.includeText ?? 'true'}` !== 'false';

    const entries = [];
    for (let page = 1; page <= pages; page++) {
      const html = await fetchText(`${BASE_URL}/portal/bbs/B0000005/list.do?menuNo=200467&pageIndex=${page}`);
      if (!html) continue;
      entries.push(...parseList(html));
    }

    const sliced = entries.slice(0, limit);
    const enriched = [];
    for (const entry of sliced) {
      const detailHtml = await fetchText(entry.sourceUrl);
      let detail = null;
      if (detailHtml) {
        detail = await parseDetail(detailHtml, includeText);
      }
      enriched.push({ ...entry, detail });
    }

    res.json({ entries: enriched });
  } catch (error) {
    res.status(500).json({ error: String(error) });
  }
});

async function fetchText(url) {
  const response = await fetch(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    },
  });
  if (!response.ok) {
    return null;
  }
  return await response.text();
}

function parseList(html) {
  const $ = cheerio.load(html);
  const entries = [];

  const rows = $('div.board a');
  rows.each((_, el) => {
    const cols = $(el)
      .find('span.col')
      .map((__, col) => $(col).text().trim())
      .get()
      .filter(Boolean);
    const entry = buildEntry(cols, $(el).attr('href'));
    if (entry) entries.push(entry);
  });

  if (entries.length > 0) return entries;

  $('table tbody tr').each((_, tr) => {
    const cols = $(tr)
      .find('td')
      .map((__, td) => $(td).text().trim())
      .get()
      .filter(Boolean);
    const href = $(tr).find('a').attr('href');
    const entry = buildEntry(cols, href);
    if (entry) entries.push(entry);
  });

  return entries;
}

function buildEntry(cols, href) {
  if (!cols || cols.length < 7) return null;

  const registrationNo = cols[0];
  const agency = cols[1];
  const client = cols[2];
  const method = cols[3];
  const sampleFrame = cols[4];
  const pollName = cols[5];
  const registeredDate = cols[6];
  const region = cols.length >= 8 ? cols[7] : '';
  const status = cols.length >= 9 ? cols[8] : null;

  const sourceUrl = href ? new URL(href, BASE_URL).toString() : BASE_URL;

  return {
    registrationNo,
    agency,
    client,
    method,
    sampleFrame,
    pollName,
    registeredDate,
    region,
    sourceUrl,
    status,
  };
}

async function parseDetail(html, includeText) {
  const $ = cheerio.load(html);
  const fields = {};

  $('th').each((_, th) => {
    const label = $(th).text().trim();
    const value = $(th).next('td').text().trim();
    if (label && value) fields[label] = value;
  });

  $('dt').each((_, dt) => {
    const label = $(dt).text().trim();
    const value = $(dt).next('dd').text().trim();
    if (label && value) fields[label] = value;
  });

  const bodyText = includeText ? $('body').text().trim() : null;
  const tableText = includeText ? extractTableText($) : null;
  const detailText = mergeDetailText(bodyText, tableText);
  const surveyDate = parseSurveyDate(fields, detailText);
  const sampleSize = parseSampleSize(fields, detailText);
  const marginOfError = parseMarginOfError(fields, detailText);

  const resultFileUrl = findResultFileUrl($);
  let resultText = null;
  if (resultFileUrl) {
    const pdfText = await tryExtractPdfText(resultFileUrl);
    if (pdfText && includeText) {
      resultText = pdfText;
    } else if (includeText) {
      const ocrText = await tryOcrExtract(resultFileUrl);
      if (ocrText) resultText = ocrText;
    }
  }

  return {
    surveyDate,
    sampleSize,
    marginOfError,
    resultFileUrl,
    detailText,
    resultText,
    fields,
  };
}

function parseSurveyDate(fields, fallbackText) {
  const candidates = [fields['조사기간'], fields['조사일시'], fields['조사일']];
  for (const value of candidates) {
    const date = parseDateFromText(value);
    if (date) return date;
  }
  return parseDateFromText(fallbackText);
}

function parseDateFromText(text) {
  if (!text) return null;
  const rangeMatch = text.match(/(\d{4}[-./]\d{1,2}[-./]\d{1,2}).*?(\d{4}[-./]\d{1,2}[-./]\d{1,2})/);
  if (rangeMatch) return normalizeDate(rangeMatch[2]);
  const singleMatch = text.match(/(\d{4}[-./]\d{1,2}[-./]\d{1,2})/);
  if (singleMatch) return normalizeDate(singleMatch[1]);
  return null;
}

function normalizeDate(token) {
  if (!token) return null;
  return token.replaceAll('.', '-').replaceAll('/', '-');
}

function parseSampleSize(fields, fallbackText) {
  const candidates = [fields['표본크기'], fields['표본'], fields['표본수']];
  for (const value of candidates) {
    const parsed = parseSampleSizeFromText(value);
    if (parsed) return parsed;
  }
  return parseSampleSizeFromText(fallbackText);
}

function parseSampleSizeFromText(text) {
  if (!text) return null;
  const match = text.match(/([0-9,]{3,})\s*명/);
  if (!match) return null;
  return Number(match[1].replaceAll(',', ''));
}

function parseMarginOfError(fields, fallbackText) {
  const candidates = [fields['표본오차'], fields['오차범위'], fields['오차한계']];
  for (const value of candidates) {
    const parsed = parseMarginFromText(value);
    if (parsed != null) return parsed;
  }
  return parseMarginFromText(fallbackText);
}

function parseMarginFromText(text) {
  if (!text) return null;
  const strictMatch = text.match(/±\s*([0-9]+(?:\.[0-9]+)?)\s*%p?/) || text.match(/([0-9]+(?:\.[0-9]+)?)\s*%p/);
  if (strictMatch) {
    const value = Number(strictMatch[1]);
    if (!Number.isNaN(value) && value <= 20) return value;
    return null;
  }

  const looseMatch = text.match(/([0-9]+(?:\.[0-9]+)?)\s*%/);
  if (!looseMatch) return null;
  const value = Number(looseMatch[1]);
  if (Number.isNaN(value) || value > 20) return null;
  if (text.includes('신뢰') || text.includes('유의')) return null;
  return value;
}

function pickLinkRaw($, link) {
  const href = ($(link).attr('href') || '').trim();
  const onclick = ($(link).attr('onclick') || '').trim();
  const dataUrl =
    $(link).attr('data-url') ||
    $(link).attr('data-href') ||
    $(link).attr('data-download') ||
    $(link).attr('data-file');
  const dataValue = (dataUrl || '').trim();
  if (dataValue) return dataValue;
  if (onclick && isJunkHref(href)) return onclick;
  if (href && !isJunkHref(href)) return href;
  if (onclick) return onclick;
  return null;
}

function isJunkHref(href) {
  const lower = (href || '').trim().toLowerCase();
  return (
    !lower ||
    lower === '#' ||
    lower === 'javascript:void(0);' ||
    lower === 'javascript:;' ||
    lower.startsWith('javascript:') ||
    lower === 'void(0)'
  );
}

function isRootUrl(url) {
  try {
    const parsed = new URL(url);
    const base = new URL(BASE_URL);
    return parsed.host === base.host && (!parsed.pathname || parsed.pathname === '/');
  } catch (_) {
    return false;
  }
}

function extractQuotedArgs(text) {
  const args = [];
  const regex = /'([^']*)'|\"([^\"]*)\"/g;
  let match = regex.exec(text);
  while (match) {
    const value = match[1] || match[2];
    if (value !== undefined) args.push(value);
    match = regex.exec(text);
  }
  return args;
}

function extractTableText($) {
  const lines = [];
  $('table tr').each((_, row) => {
    const cells = $(row)
      .find('th, td')
      .map((__, cell) => $(cell).text().trim())
      .get()
      .filter(Boolean);
    if (cells.length) lines.push(cells.join(' '));
  });
  if (lines.length === 0) return null;
  return lines.join('\n');
}

function mergeDetailText(bodyText, tableText) {
  const parts = [];
  if (bodyText && bodyText.trim()) parts.push(bodyText.trim());
  if (tableText && tableText.trim()) parts.push(tableText.trim());
  if (parts.length === 0) return null;
  return parts.join('\n');
}

function findResultFileUrl($) {
  let pdfUrl = null;
  let otherUrl = null;

  const candidates = [
    ...$('div[id^="realfile_"] a').toArray(),
    ...$('.file a').toArray(),
    ...$('a').toArray(),
  ];

  for (const link of candidates) {
    const raw = pickLinkRaw($, link);
    if (!raw) continue;

    const resolved = resolveAttachmentUrl(raw);
    if (!resolved || isRootUrl(resolved)) continue;

    const lower = resolved.toLowerCase();
    if (lower.endsWith('.pdf')) {
      pdfUrl = resolved;
      break;
    }

    const isAttachment =
      raw.includes('fileDown') ||
      raw.includes('FileDown') ||
      raw.includes('view(') ||
      lower.includes('filedown');
    if (!otherUrl && isAttachment) {
      otherUrl = resolved;
    }
  }

  return pdfUrl || otherUrl;
}

function resolveAttachmentUrl(raw) {
  const trimmed = raw.trim();
  const viewMatch = trimmed.match(/view\(([^)]*)\)/);
  if (viewMatch) {
    const args = extractQuotedArgs(viewMatch[1]);
    if (args.length >= 4) {
      const base = new URL('/portal/cmm/fms/FileDown.do', BASE_URL).toString();
      const query = `atchFileId=${args[0]}&fileSn=${args[1]}&bbsId=${args[2]}&bbsKey=${args[3]}`;
      return `${base}?${query}`;
    }
  }

  if (trimmed.includes('FileDown') || trimmed.includes('fileDown')) {
    const match = trimmed.match(/(https?:\/\/[^\s'"]+)/);
    if (match) return match[1];
    const funcMatch = trimmed.match(/\(([^)]*)\)/);
    if (funcMatch) {
      const inside = funcMatch[1];
      const args = extractQuotedArgs(inside);
      if (args.length > 0) {
        const candidate = args[0];
        if (candidate.startsWith('/')) return new URL(candidate, BASE_URL).toString();
        if (candidate.startsWith('http')) return candidate;
      }
    }
    const hrefMatch = trimmed.match(/(\/[^\s]+fileDown[^\s]+)/);
    if (hrefMatch) return new URL(hrefMatch[1], BASE_URL).toString();
  }

  if (trimmed.startsWith('javascript')) return null;
  if (trimmed.startsWith('/')) return new URL(trimmed, BASE_URL).toString();
  if (trimmed.startsWith('http')) return trimmed;
  return null;
}

async function tryExtractPdfText(url) {
  try {
    const response = await fetch(url);
    if (!response.ok) return null;
    const buffer = Buffer.from(await response.arrayBuffer());
    const data = await pdfParse(buffer, {
      pagerender: renderPageWithLayout,
    });
    if (data.text && data.text.trim()) {
      return data.text;
    }
    const fallback = await pdfParse(buffer);
    return fallback.text || null;
  } catch (_) {
    return null;
  }
}

async function renderPageWithLayout(pageData) {
  const textContent = await pageData.getTextContent();
  const items = textContent.items || [];
  const lines = [];
  let currentY = null;
  let line = [];

  for (const item of items) {
    const transform = item.transform || [];
    const x = transform[4] || 0;
    const y = transform[5] || 0;
    const text = (item.str || '').trim();
    if (!text) continue;

    if (currentY === null || Math.abs(y - currentY) > 2) {
      if (line.length) {
        line.sort((a, b) => a.x - b.x);
        lines.push(line.map((t) => t.text).join(' '));
      }
      line = [];
      currentY = y;
    }
    line.push({ x, text });
  }

  if (line.length) {
    line.sort((a, b) => a.x - b.x);
    lines.push(line.map((t) => t.text).join(' '));
  }

  return lines.join('\n');
}

async function tryOcrExtract(url) {
  const endpoint = process.env.NESDC_OCR_ENDPOINT;
  if (!endpoint) return null;
  try {
    const response = await fetch(url);
    if (!response.ok) return null;
    const buffer = Buffer.from(await response.arrayBuffer());
    const ocrResponse = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/pdf',
      },
      body: buffer,
    });
    if (!ocrResponse.ok) return null;
    const text = await ocrResponse.text();
    return text && text.trim() ? text : null;
  } catch (_) {
    return null;
  }
}

const port = Number(process.env.PORT || 8787);
app.listen(port, () => {
  console.log(`NESDC backend running on port ${port}`);
});
