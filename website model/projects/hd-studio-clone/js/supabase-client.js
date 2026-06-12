const SUPABASE_URL = window.__env?.SUPABASE_URL || 'https://mevrjrispvjmtykbvmbc.supabase.co';
const SUPABASE_ANON_KEY = window.__env?.SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ldnJqcmlzcHZqbXR5a2J2bWJjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyNTk4NjEsImV4cCI6MjA5NjgzNTg2MX0.KolRBKA2XkoPcXZJfRoNxymIHyxOXzKdDz9gujWC67E';

const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
export default supabase;
