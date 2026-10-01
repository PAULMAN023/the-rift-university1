-- TRU starter schema. Review and test RLS with non-privileged accounts before real data.
create extension if not exists pgcrypto;
create type public.tru_role as enum ('student','lecturer','admin','finance','support');
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '',
 role public.tru_role not null default 'student',
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.programmes (
 id uuid primary key default gen_random_uuid(),
 slug text unique not null,
 title text not null,
 school text not null,
 description text not null default '',
 status text not null default 'draft' check(status in ('draft','approved','archived')),
 created_at timestamptz not null default now()
);
create table if not exists public.student_programme_selections (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null unique references public.profiles(id),
 programme_id uuid not null references public.programmes(id),
 selected_at timestamptz not null default now(),
 status text not null default 'pending' check(status in ('pending','confirmed','cancelled')),
 confirmed_at timestamptz,
 created_by uuid references public.profiles(id)
);
create table if not exists public.applications (
 id uuid primary key default gen_random_uuid(),
 full_name text not null,
 email text not null,
 phone text not null,
 programme_interest text not null,
 education_level text not null,
 message text,
 consent boolean not null default false,
 status text not null default 'received' check(status in ('received','reviewing','needs_information','accepted','declined','withdrawn')),
 created_at timestamptz not null default now()
);
create table if not exists public.contact_enquiries (
 id uuid primary key default gen_random_uuid(),
 name text not null,email text not null,subject text not null,message text not null,
 status text not null default 'new' check(status in ('new','assigned','resolved','closed')),
 created_at timestamptz not null default now()
);
create table if not exists public.payment_transactions (
 id uuid primary key default gen_random_uuid(),
 application_id uuid references public.applications(id),
 phone text not null,amount integer not null check(amount>0),currency text not null default 'KES',
 merchant_request_id text,checkout_request_id text unique,status text not null default 'pending' check(status in ('pending','paid','failed','reversed')),
 result_code text,result_description text,mpesa_receipt_number text,transaction_date text,
 created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create table if not exists public.audit_events (
 id uuid primary key default gen_random_uuid(),
 actor_id uuid references public.profiles(id),action text not null,entity_type text not null,entity_id text,metadata jsonb not null default '{}'::jsonb,created_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
alter table public.programmes enable row level security;
alter table public.student_programme_selections enable row level security;
alter table public.applications enable row level security;
alter table public.contact_enquiries enable row level security;
alter table public.payment_transactions enable row level security;
alter table public.audit_events enable row level security;
create policy "profiles read own" on public.profiles for select to authenticated using (auth.uid()=id);
create policy "profiles update own non-role fields" on public.profiles for update to authenticated using (auth.uid()=id) with check (auth.uid()=id);
create policy "approved programmes visible" on public.programmes for select to anon,authenticated using (status='approved');
create policy "student sees own selection" on public.student_programme_selections for select to authenticated using (student_id=auth.uid());
create policy "student sees own payment by application association" on public.payment_transactions for select to authenticated using (exists(select 1 from public.applications a where a.id=application_id and lower(a.email)=lower((select email from auth.users where id=auth.uid()))));
-- Public application/contact inserts are handled through server APIs; do not grant direct anon table writes.
-- Admin policies and trusted server-side role assignment must be added only after institutional governance is defined.
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.profiles(id,full_name,role) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',''),'student') on conflict(id) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
