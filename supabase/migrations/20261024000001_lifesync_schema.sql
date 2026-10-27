-- ==============================================================================
-- LIFESYNC — Adaptive Personal Life Intelligence System
-- Migration: 20261024000001_lifesync_schema.sql
-- Description: Complete schema with UUIDs, Foreign Keys, CHECK constraints, Indexes,
--              Triggers, and comprehensive Row Level Security (RLS) policies.
-- ==============================================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------------------------
-- 1. PROFILES
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    timezone TEXT NOT NULL DEFAULT 'UTC',
    daily_available_minutes INTEGER NOT NULL DEFAULT 180 CHECK (daily_available_minutes > 0),
    planning_preferences JSONB NOT NULL DEFAULT '{"preferredStrategy": "PriorityFirst", "energyPeak": "Morning", "allowSplitting": true}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 2. LIFE AREAS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.life_areas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    color TEXT NOT NULL DEFAULT '#14B8A6', -- teal default
    priority INTEGER NOT NULL DEFAULT 2 CHECK (priority BETWEEN 1 AND 4),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 3. GOALS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    life_area_id UUID NOT NULL REFERENCES public.life_areas(id) ON DELETE RESTRICT,
    title TEXT NOT NULL,
    description TEXT,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    target_date DATE NOT NULL,
    priority INTEGER NOT NULL DEFAULT 2 CHECK (priority BETWEEN 1 AND 4),
    status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Completed', 'Paused', 'Archived')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 4. TASKS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    goal_id UUID REFERENCES public.goals(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    estimated_minutes INTEGER NOT NULL CHECK (estimated_minutes > 0),
    priority INTEGER NOT NULL DEFAULT 2 CHECK (priority BETWEEN 1 AND 4),
    due_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Scheduled', 'InProgress', 'Completed', 'Postponed', 'Skipped', 'Cancelled')),
    task_type TEXT NOT NULL DEFAULT 'Standard' CHECK (task_type IN ('Standard', 'DeepWork', 'QuickTask', 'FixedAppointment')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 5. FIXED COMMITMENTS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.fixed_commitments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    recurrence_rule TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_commitment_time_window CHECK (end_time > start_time)
);

-- ------------------------------------------------------------------------------
-- 6. TASK LOGS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.task_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    action TEXT NOT NULL, -- e.g. 'CREATED', 'COMPLETED', 'POSTPONED', 'SPLIT'
    previous_status TEXT,
    new_status TEXT NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- ------------------------------------------------------------------------------
-- 7. REFLECTIONS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reflections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reflection_date DATE NOT NULL,
    wins TEXT NOT NULL,
    challenges TEXT NOT NULL,
    next_step TEXT NOT NULL,
    self_reported_workload INTEGER CHECK (self_reported_workload BETWEEN 1 AND 5),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_user_reflection_date UNIQUE (user_id, reflection_date)
);

-- ------------------------------------------------------------------------------
-- 8. USER CONSTRAINTS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_constraints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    constraint_type TEXT NOT NULL, -- 'MAX_DAILY_MINUTES', 'NO_STUDY_AFTER_21', etc.
    value TEXT NOT NULL,
    effective_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    effective_until TIMESTAMPTZ
);

-- ------------------------------------------------------------------------------
-- 9. PLAN SNAPSHOTS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.plan_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    plan_type TEXT NOT NULL DEFAULT 'Active' CHECK (plan_type IN ('Active', 'Candidate', 'Scenario', 'Recovery', 'Archived')),
    strategy TEXT NOT NULL CHECK (strategy IN ('PriorityFirst', 'DeadlineSensitive', 'BalanceFirst', 'RecoveryFirst')),
    score DOUBLE PRECISION NOT NULL DEFAULT 0.0 CHECK (score >= 0.0),
    scoring_version TEXT NOT NULL DEFAULT 'v1.0',
    summary JSONB NOT NULL DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft', 'Applied', 'Discarded', 'Superseded')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 10. PLAN ITEMS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.plan_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES public.plan_snapshots(id) ON DELETE CASCADE,
    task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
    scheduled_start TIMESTAMPTZ NOT NULL,
    scheduled_end TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'Scheduled' CHECK (status IN ('Scheduled', 'Completed', 'Skipped', 'Missed')),
    CONSTRAINT chk_plan_item_time_window CHECK (scheduled_end > scheduled_start)
);

-- ------------------------------------------------------------------------------
-- 11. SCENARIOS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.scenarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    baseline_plan_id UUID REFERENCES public.plan_snapshots(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'Draft' CHECK (status IN ('Draft', 'Applied', 'Discarded')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 12. SCENARIO CHANGES
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.scenario_changes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scenario_id UUID NOT NULL REFERENCES public.scenarios(id) ON DELETE CASCADE,
    field_name TEXT NOT NULL,
    old_value JSONB,
    new_value JSONB
);

-- ------------------------------------------------------------------------------
-- 13. RECOVERY PLANS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.recovery_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    trigger_reason TEXT NOT NULL,
    source_plan_id UUID REFERENCES public.plan_snapshots(id) ON DELETE SET NULL,
    proposed_plan_id UUID REFERENCES public.plan_snapshots(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'Proposed' CHECK (status IN ('Proposed', 'Accepted', 'Rejected', 'Edited')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    accepted_at TIMESTAMPTZ
);

-- ------------------------------------------------------------------------------
-- 14. INSIGHTS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    insight_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    evidence_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    sample_size INTEGER NOT NULL CHECK (sample_size >= 0),
    observation_start TIMESTAMPTZ NOT NULL,
    observation_end TIMESTAMPTZ NOT NULL,
    evidence_strength TEXT NOT NULL CHECK (evidence_strength IN ('Preliminary', 'Moderate', 'Strong')),
    status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Dismissed', 'Investigated')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 15. EXPERIMENTS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.experiments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    insight_id UUID REFERENCES public.insights(id) ON DELETE SET NULL,
    hypothesis TEXT NOT NULL,
    change_description TEXT NOT NULL,
    metric_definition TEXT NOT NULL,
    baseline_period_start TIMESTAMPTZ NOT NULL,
    baseline_period_end TIMESTAMPTZ NOT NULL,
    experiment_start TIMESTAMPTZ NOT NULL,
    experiment_end TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Draft', 'Active', 'Completed', 'Cancelled', 'Adopted')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_experiment_window CHECK (experiment_end > experiment_start)
);

-- ------------------------------------------------------------------------------
-- 16. EXPERIMENT RESULTS
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.experiment_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    experiment_id UUID NOT NULL REFERENCES public.experiments(id) ON DELETE CASCADE,
    metric_name TEXT NOT NULL,
    baseline_value DOUBLE PRECISION NOT NULL,
    result_value DOUBLE PRECISION NOT NULL,
    sample_size INTEGER NOT NULL CHECK (sample_size >= 0),
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    limitations TEXT NOT NULL
);

-- ==============================================================================
-- INDEXES FOR HIGH-EFFICIENCY QUERY PATTERNS
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_life_areas_user ON public.life_areas(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_user ON public.goals(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_life_area ON public.goals(life_area_id);
CREATE INDEX IF NOT EXISTS idx_tasks_user_status ON public.tasks(user_id, status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_at ON public.tasks(due_at);
CREATE INDEX IF NOT EXISTS idx_task_logs_task ON public.task_logs(task_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_task_logs_user ON public.task_logs(user_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_fixed_commitments_user ON public.fixed_commitments(user_id, start_time);
CREATE INDEX IF NOT EXISTS idx_reflections_user_date ON public.reflections(user_id, reflection_date DESC);
CREATE INDEX IF NOT EXISTS idx_plan_snapshots_user_type ON public.plan_snapshots(user_id, plan_type);
CREATE INDEX IF NOT EXISTS idx_plan_items_plan ON public.plan_items(plan_id);
CREATE INDEX IF NOT EXISTS idx_insights_user ON public.insights(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_experiments_user ON public.experiments(user_id, status);

-- ==============================================================================
-- UPDATED_AT TRIGGER FUNCTION
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.set_current_timestamp_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

CREATE TRIGGER trg_goals_updated_at BEFORE UPDATE ON public.goals
FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

CREATE TRIGGER trg_tasks_updated_at BEFORE UPDATE ON public.tasks
FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.life_areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fixed_commitments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reflections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_constraints ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scenario_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recovery_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.experiments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.experiment_results ENABLE ROW LEVEL SECURITY;

-- 1. Profiles Policy
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can delete own profile" ON public.profiles FOR DELETE USING (auth.uid() = id);

-- 2. Life Areas Policy
CREATE POLICY "Users can CRUD own life areas" ON public.life_areas FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3. Goals Policy
CREATE POLICY "Users can CRUD own goals" ON public.goals FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 4. Tasks Policy
CREATE POLICY "Users can CRUD own tasks" ON public.tasks FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 5. Fixed Commitments Policy
CREATE POLICY "Users can CRUD own fixed commitments" ON public.fixed_commitments FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 6. Task Logs Policy
CREATE POLICY "Users can CRUD own task logs" ON public.task_logs FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 7. Reflections Policy
CREATE POLICY "Users can CRUD own reflections" ON public.reflections FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 8. User Constraints Policy
CREATE POLICY "Users can CRUD own constraints" ON public.user_constraints FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 9. Plan Snapshots Policy
CREATE POLICY "Users can CRUD own plan snapshots" ON public.plan_snapshots FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 10. Plan Items Policy (Through plan ownership)
CREATE POLICY "Users can CRUD own plan items" ON public.plan_items FOR ALL USING (
    EXISTS (SELECT 1 FROM public.plan_snapshots WHERE plan_snapshots.id = plan_items.plan_id AND plan_snapshots.user_id = auth.uid())
) WITH CHECK (
    EXISTS (SELECT 1 FROM public.plan_snapshots WHERE plan_snapshots.id = plan_items.plan_id AND plan_snapshots.user_id = auth.uid())
);

-- 11. Scenarios Policy
CREATE POLICY "Users can CRUD own scenarios" ON public.scenarios FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 12. Scenario Changes Policy (Through scenario ownership)
CREATE POLICY "Users can CRUD own scenario changes" ON public.scenario_changes FOR ALL USING (
    EXISTS (SELECT 1 FROM public.scenarios WHERE scenarios.id = scenario_changes.scenario_id AND scenarios.user_id = auth.uid())
) WITH CHECK (
    EXISTS (SELECT 1 FROM public.scenarios WHERE scenarios.id = scenario_changes.scenario_id AND scenarios.user_id = auth.uid())
);

-- 13. Recovery Plans Policy
CREATE POLICY "Users can CRUD own recovery plans" ON public.recovery_plans FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 14. Insights Policy
CREATE POLICY "Users can CRUD own insights" ON public.insights FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 15. Experiments Policy
CREATE POLICY "Users can CRUD own experiments" ON public.experiments FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 16. Experiment Results Policy (Through experiment ownership)
CREATE POLICY "Users can CRUD own experiment results" ON public.experiment_results FOR ALL USING (
    EXISTS (SELECT 1 FROM public.experiments WHERE experiments.id = experiment_results.experiment_id AND experiments.user_id = auth.uid())
) WITH CHECK (
    EXISTS (SELECT 1 FROM public.experiments WHERE experiments.id = experiment_results.experiment_id AND experiments.user_id = auth.uid())
);
