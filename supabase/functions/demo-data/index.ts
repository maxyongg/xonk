// demo-data — serves one user's list publicly as the app's example data.
// Deploy in Supabase: Edge Functions -> Deploy new function -> name it
// exactly "demo-data" -> paste this file -> Deploy.
// IMPORTANT: turn OFF "Verify JWT" for this function (it must be reachable
// by signed-out visitors), and add a secret DEMO_USERNAME = your username.

import { createClient } from "jsr:@supabase/supabase-js@2";

const supa = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);
const DEMO_USERNAME = Deno.env.get("DEMO_USERNAME") ?? "";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json", "Cache-Control": "public, max-age=300" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const { data: prof } = await supa.from("profiles").select("id").eq("username", DEMO_USERNAME).single();
  if (!prof) return json({ error: "demo user not configured" }, 404);
  const { data: items, error } = await supa
    .from("items")
    .select("id,kind,name,cover_url,creator,year,date_logged,rx,ry,summary,genre,in_progress,extra")
    .eq("user_id", prof.id);
  if (error) return json({ error: error.message }, 500);
  return json({ items });
});
