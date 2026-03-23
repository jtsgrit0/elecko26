const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': '*',
};

export default {
  async fetch(request) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    const target = url.searchParams.get('url');
    if (!target) {
      return new Response('Missing url parameter', { status: 400, headers: corsHeaders });
    }

    if (!target.startsWith('https://www.nesdc.go.kr/')) {
      return new Response('Forbidden', { status: 403, headers: corsHeaders });
    }

    const upstream = await fetch(target, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      },
    });

    const headers = new Headers(upstream.headers);
    Object.entries(corsHeaders).forEach(([key, value]) => headers.set(key, value));

    return new Response(upstream.body, { status: upstream.status, headers });
  },
};
