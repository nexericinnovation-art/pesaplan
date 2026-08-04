import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
<<<<<<< HEAD

serve(async (req) => {
  try {
    const payload = await req.json();
    const { clerkUserId } = payload;

    if (!clerkUserId) {
      return new Response(JSON.stringify({ error: 'Missing clerkUserId' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
=======
import * as jose from 'https://esm.sh/jose@5';

// Verifies the caller's Clerk session token and returns the verified Clerk
// user id (the JWT `sub` claim). Never trust a client-supplied user id for
// a server-side, service-role-authenticated write.
async function verifyClerkUserId(req: Request): Promise<string> {
  const authHeader = req.headers.get('authorization') ?? '';
  const match = authHeader.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    throw new Response(JSON.stringify({ error: 'Missing bearer session token' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }
  const token = match[1];

  const jwksUrl = Deno.env.get('CLERK_JWKS_URL');
  if (!jwksUrl) {
    throw new Response(JSON.stringify({ error: 'Missing server-side Clerk JWKS configuration' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  try {
    const JWKS = jose.createRemoteJWKSet(new URL(jwksUrl));
    const { payload } = await jose.jwtVerify(token, JWKS);
    if (typeof payload.sub !== 'string' || payload.sub.length === 0) {
      throw new Error('Token missing sub claim');
    }
    return payload.sub;
  } catch (_err) {
    throw new Response(JSON.stringify({ error: 'Invalid or expired session token' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}

serve(async (req) => {
  try {
    let verifiedClerkUserId: string;
    try {
      verifiedClerkUserId = await verifyClerkUserId(req);
    } catch (response) {
      if (response instanceof Response) return response;
      throw response;
>>>>>>> temp-work
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      return new Response(JSON.stringify({ error: 'Missing server-side Supabase configuration' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

<<<<<<< HEAD
    const { data, error } = await supabase
      .from('profiles')
      .upsert({ clerk_user_id: clerkUserId }, { onConflict: 'clerk_user_id' })
=======
    // Always use the verified sub from the token, never a client-supplied value.
    const { data, error } = await supabase
      .from('profiles')
      .upsert({ clerk_user_id: verifiedClerkUserId }, { onConflict: 'clerk_user_id' })
>>>>>>> temp-work
      .select('id, clerk_user_id, created_at')
      .single();

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ profile: data }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Unhandled error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
