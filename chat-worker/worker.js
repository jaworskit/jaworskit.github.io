/**
 * Cloudflare Worker: Course Chat Assistant Proxy
 *
 * Proxies requests from the course website chat widget to the Claude API.
 * Deploy to Cloudflare Workers and set your API key as a secret:
 *
 *   npx wrangler secret put ANTHROPIC_API_KEY
 *
 * Then update API_ENDPOINT in js/chat.js to your worker URL.
 *
 * wrangler.toml example:
 *
 *   name = "course-chat"
 *   main = "worker.js"
 *   compatibility_date = "2024-01-01"
 *
 *   [vars]
 *   ALLOWED_ORIGIN = "https://jaworskit.github.io"
 */

var CORS_HEADERS = {
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Max-Age': '86400'
};

function corsHeaders(origin, env) {
  var allowed = env.ALLOWED_ORIGIN || 'https://jaworskit.github.io';
  var headers = Object.assign({}, CORS_HEADERS);
  if (origin === allowed || allowed === '*') {
    headers['Access-Control-Allow-Origin'] = origin;
  } else {
    headers['Access-Control-Allow-Origin'] = allowed;
  }
  return headers;
}

// ── System prompts per course ───────────────────────
var SYSTEM_PROMPTS = {
  'us-econ-history': [
    'You are a teaching assistant for ECON 4524: Economic History of the United States,',
    'taught by Professor Taylor Jaworski at the University of Colorado Boulder.',
    '',
    'The course examines American economic growth and inequality from the Revolution to the present,',
    'framed around Tocqueville\'s observations about equality of conditions in America.',
    '',
    'Course topics (in order):',
    '1. Can Capitalism and Democracy Coexist?',
    '2. Production Functions',
    '3. The Americas Before and After Columbus',
    '4. The Colonial Economy',
    '5. The American Revolution',
    '6. The Early Republic',
    '7. Slavery and the Civil War',
    '8. The Development of American Agriculture',
    '9. The Market Revolution',
    '10. From Industrialization to Big Business',
    '11. The Age of Mass Migration',
    '12. The Great Depression and World War II',
    '13. Education, Skills, and the Evolution of Work',
    '14. The Future of US Growth and Inequality',
    '',
    'Guidelines:',
    '- Help students understand course material, economic concepts, and historical context.',
    '- When relevant, refer students to specific readings from the course outline.',
    '- Use clear, accessible language appropriate for undergraduate students.',
    '- Do not write essays, problem sets, or exam answers for students.',
    '- If a question is outside the course scope, briefly note that and redirect.',
    '- Keep responses concise (2-4 paragraphs maximum).',
    '- Do not use em dashes or en dashes. Use commas, periods, or parentheses instead.'
  ].join('\n'),

  'eu-econ-history': [
    'You are a teaching assistant for ECON 4514: European Economic History,',
    'taught by Professor Taylor Jaworski at the University of Colorado Boulder.',
    '',
    'The course traces the emergence of the modern economy in Europe from roughly 1000 CE to the present,',
    'covering preconditions for growth, the Industrial Revolution, global integration, world wars,',
    'and postwar European integration.',
    '',
    'Course topics (in order):',
    '1. Economic Growth in the Very Long Run',
    '2. The Economy of the Ancient World',
    '3. Political Instability in Medieval Times',
    '4. Disease, the Black Death and the Renaissance',
    '5. Institutions, Legitimacy and Economic Development',
    '6. The Enlightenment, Science, and Useful Ideas',
    '7. The Industrial Revolution',
    '8. Globalization and Empire',
    '9. World War I',
    '10. Interwar Macroeconomics',
    '11. World War II',
    '12. The Postwar Golden Age',
    '13. The European Union',
    '14. The End of History',
    '',
    'Required textbooks:',
    '- Persson & Sharp, An Economic History of Europe',
    '- Eichengreen, The European Economy since 1945',
    '',
    'Guidelines:',
    '- Help students understand course material, economic concepts, and historical context.',
    '- When relevant, refer students to specific readings or textbook chapters.',
    '- Use clear, accessible language appropriate for undergraduate students.',
    '- Do not write essays, problem sets, or exam answers for students.',
    '- If a question is outside the course scope, briefly note that and redirect.',
    '- Keep responses concise (2-4 paragraphs maximum).',
    '- Do not use em dashes or en dashes. Use commas, periods, or parentheses instead.'
  ].join('\n')
};

var DEFAULT_PROMPT = 'You are a helpful teaching assistant for an economics course. Help students understand course material without doing their work for them. Keep responses concise.';

// ── Request handler ─────────────────────────────────
export default {
  async fetch(request, env) {
    var origin = request.headers.get('Origin') || '';
    var headers = corsHeaders(origin, env);

    // Handle preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: headers });
    }

    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405, headers: headers });
    }

    try {
      var body = await request.json();
      var userMessages = body.messages || [];
      var courseId = body.course || 'general';

      // Basic validation
      if (!userMessages.length) {
        return new Response(
          JSON.stringify({ error: 'No messages provided' }),
          { status: 400, headers: Object.assign({ 'Content-Type': 'application/json' }, headers) }
        );
      }

      // Limit conversation length sent to API
      var recentMessages = userMessages.slice(-20);

      var systemPrompt = SYSTEM_PROMPTS[courseId] || DEFAULT_PROMPT;

      var apiResponse = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': env.ANTHROPIC_API_KEY,
          'anthropic-version': '2023-06-01'
        },
        body: JSON.stringify({
          model: 'claude-haiku-4-5-20251001',
          max_tokens: 1024,
          system: systemPrompt,
          messages: recentMessages
        })
      });

      if (!apiResponse.ok) {
        var errText = await apiResponse.text();
        console.error('Claude API error:', apiResponse.status, errText);
        return new Response(
          JSON.stringify({ error: 'API request failed' }),
          { status: 502, headers: Object.assign({ 'Content-Type': 'application/json' }, headers) }
        );
      }

      var data = await apiResponse.json();

      return new Response(JSON.stringify(data), {
        status: 200,
        headers: Object.assign({ 'Content-Type': 'application/json' }, headers)
      });

    } catch (err) {
      console.error('Worker error:', err);
      return new Response(
        JSON.stringify({ error: 'Internal error' }),
        { status: 500, headers: Object.assign({ 'Content-Type': 'application/json' }, headers) }
      );
    }
  }
};
