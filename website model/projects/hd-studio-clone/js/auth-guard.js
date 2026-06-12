import supabase from './supabase-client.js';

const { data: { session } } = await supabase.auth.getSession();
if (!session) {
  const redirect = encodeURIComponent(window.location.href);
  window.location.replace(`/pages/login.html?redirect=${redirect}`);
}

export const currentUser = session?.user ?? null;
export const currentRole = session?.user?.user_metadata?.role ?? 'user';
