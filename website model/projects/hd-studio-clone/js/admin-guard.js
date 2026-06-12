import supabase from './supabase-client.js';

const { data: { session } } = await supabase.auth.getSession();
if (!session) {
  const redirect = encodeURIComponent(window.location.href);
  window.location.replace(`/pages/login.html?redirect=${redirect}`);
}

const role = session?.user?.user_metadata?.role ?? 'user';
if (role !== 'admin') {
  window.location.replace('/pages/unauthorized.html');
}

export const currentUser = session?.user ?? null;
export const currentRole = role;
