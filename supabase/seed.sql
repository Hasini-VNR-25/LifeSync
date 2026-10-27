-- ==============================================================================
-- LIFESYNC — Adaptive Personal Life Intelligence System
-- Seed File: seed.sql
-- Demonstration Scenario: College Student Capacity Mismatch (180 mins vs 200 mins)
-- ==============================================================================

-- Create a mock test user in auth.users if running in local Supabase studio
DO $$
DECLARE
    demo_user_id UUID := 'd0000000-0000-0000-0000-000000000001';
    area_academics_id UUID := 'a0000000-0000-0000-0000-000000000001';
    area_career_id UUID := 'a0000000-0000-0000-0000-000000000002';
    area_health_id UUID := 'a0000000-0000-0000-0000-000000000003';
    area_personal_id UUID := 'a0000000-0000-0000-0000-000000000004';
    
    goal_dbms_id UUID := 'g0000000-0000-0000-0000-000000000001';
    goal_java_id UUID := 'g0000000-0000-0000-0000-000000000002';
    goal_placement_id UUID := 'g0000000-0000-0000-0000-000000000003';
    goal_fitness_id UUID := 'g0000000-0000-0000-0000-000000000004';
    goal_reading_id UUID := 'g0000000-0000-0000-0000-000000000005';
BEGIN
    -- 1. Insert Profile
    INSERT INTO public.profiles (id, display_name, timezone, daily_available_minutes, planning_preferences)
    VALUES (
        demo_user_id,
        'Alex Rivera (CS Student)',
        'Asia/Kolkata',
        180,
        '{"preferredStrategy": "PriorityFirst", "energyPeak": "Morning", "allowSplitting": true}'::jsonb
    ) ON CONFLICT (id) DO UPDATE SET
        daily_available_minutes = 180,
        display_name = 'Alex Rivera (CS Student)';

    -- 2. Insert Life Areas
    INSERT INTO public.life_areas (id, user_id, name, description, color, priority, is_active)
    VALUES
        (area_academics_id, demo_user_id, 'Academics & Learning', 'Core coursework and university exams', '#3B82F6', 4, true),
        (area_career_id, demo_user_id, 'Career & Placement', 'Internship & placement prep', '#10B981', 3, true),
        (area_health_id, demo_user_id, 'Health & Fitness', 'Physical and mental well-being', '#F59E0B', 3, true),
        (area_personal_id, demo_user_id, 'Personal Growth', 'Reading and habits', '#8B5CF6', 2, true)
    ON CONFLICT (id) DO NOTHING;

    -- 3. Insert Goals
    INSERT INTO public.goals (id, user_id, life_area_id, title, description, start_date, target_date, priority, status)
    VALUES
        (goal_dbms_id, demo_user_id, area_academics_id, 'Score A+ in DBMS Coursework', 'Finish all assignments and relational schema design', CURRENT_DATE - 14, CURRENT_DATE + 30, 4, 'Active'),
        (goal_java_id, demo_user_id, area_academics_id, 'Master OOP in Java', 'Complete DSA problems in Java', CURRENT_DATE - 10, CURRENT_DATE + 45, 4, 'Active'),
        (goal_placement_id, demo_user_id, area_career_id, 'Campus Placement Readiness', 'Prepare for technical coding rounds and HR questions', CURRENT_DATE - 20, CURRENT_DATE + 60, 3, 'Active'),
        (goal_fitness_id, demo_user_id, area_health_id, 'Daily Cardio & Calisthenics', 'Maintain 30 mins workout 5 days a week', CURRENT_DATE - 30, CURRENT_DATE + 90, 3, 'Active'),
        (goal_reading_id, demo_user_id, area_personal_id, 'Tech & Productivity Reading', 'Read 20 pages of Deep Work daily', CURRENT_DATE - 5, CURRENT_DATE + 30, 2, 'Active')
    ON CONFLICT (id) DO NOTHING;

    -- 4. Insert Candidate Tasks (Total: 60 + 45 + 45 + 30 + 20 = 200 minutes against 180m available capacity)
    INSERT INTO public.tasks (id, user_id, goal_id, title, description, estimated_minutes, priority, due_at, status, task_type)
    VALUES
        ('t0000000-0000-0000-0000-000000000001', demo_user_id, goal_dbms_id, 'DBMS Assignment: SQL Query Optimization', 'Index tuning and join tree execution plans', 60, 4, NOW() + INTERVAL '4 hours', 'Pending', 'DeepWork'),
        ('t0000000-0000-0000-0000-000000000002', demo_user_id, goal_java_id, 'Java Practice: Concurrency & Streams', 'Solve 3 medium LeetCode concurrency challenges', 45, 4, NOW() + INTERVAL '8 hours', 'Pending', 'DeepWork'),
        ('t0000000-0000-0000-0000-000000000003', demo_user_id, goal_placement_id, 'Placement Prep: System Design Mock', 'Review caching and load balancing concepts', 45, 3, NOW() + INTERVAL '12 hours', 'Pending', 'Standard'),
        ('t0000000-0000-0000-0000-000000000004', demo_user_id, goal_fitness_id, 'Exercise: HIIT & Core Strength', '30 min interval cardio workout at gym', 30, 3, NOW() + INTERVAL '14 hours', 'Pending', 'Standard'),
        ('t0000000-0000-0000-0000-000000000005', demo_user_id, goal_reading_id, 'Personal Reading: Deep Work Ch. 3', 'Read about rhythmic and bimodal scheduling', 20, 1, NOW() + INTERVAL '16 hours', 'Pending', 'QuickTask')
    ON CONFLICT (id) DO NOTHING;

    -- 5. Insert Fixed Commitment (e.g. 1-hour Faculty Mentorship)
    INSERT INTO public.fixed_commitments (id, user_id, title, start_time, end_time, is_recurring)
    VALUES (
        'c0000000-0000-0000-0000-000000000001',
        demo_user_id,
        'Faculty Project Review & Lab',
        NOW() + INTERVAL '2 hours',
        NOW() + INTERVAL '3 hours',
        false
    ) ON CONFLICT (id) DO NOTHING;

    -- 6. Insert Sample Historical Logs for Growth Investigator Evidence
    INSERT INTO public.task_logs (user_id, task_id, action, previous_status, new_status, occurred_at, metadata)
    VALUES
        (demo_user_id, 't0000000-0000-0000-0000-000000000001', 'POSTPONED', 'Scheduled', 'Postponed', NOW() - INTERVAL '3 days', '{"reason": "Exceeded allocated slot", "originalDuration": 60}'::jsonb),
        (demo_user_id, 't0000000-0000-0000-0000-000000000001', 'POSTPONED', 'Scheduled', 'Postponed', NOW() - INTERVAL '2 days', '{"reason": "Fatigue during long block", "originalDuration": 60}'::jsonb),
        (demo_user_id, 't0000000-0000-0000-0000-000000000004', 'COMPLETED', 'Scheduled', 'Completed', NOW() - INTERVAL '3 days', '{"duration": 30, "onTime": true}'::jsonb),
        (demo_user_id, 't0000000-0000-0000-0000-000000000005', 'COMPLETED', 'Scheduled', 'Completed', NOW() - INTERVAL '2 days', '{"duration": 20, "onTime": true}'::jsonb),
        (demo_user_id, 't0000000-0000-0000-0000-000000000004', 'COMPLETED', 'Scheduled', 'Completed', NOW() - INTERVAL '1 day', '{"duration": 30, "onTime": true}'::jsonb);

    -- 7. Insert Initial Growth Investigator Insight
    INSERT INTO public.insights (id, user_id, insight_type, title, description, evidence_json, sample_size, observation_start, observation_end, evidence_strength, status)
    VALUES (
        'i0000000-0000-0000-0000-000000000001',
        demo_user_id,
        'TASK_DURATION_SENSITIVITY',
        'Shorter study sessions show 2.5x higher completion rates',
        'During the last two weeks, tasks scheduled for <= 30 minutes had an 85% completion rate, while tasks >= 60 minutes had a 34% completion rate with frequent postponements.',
        '{"shortTaskCompletionRate": 0.85, "longTaskCompletionRate": 0.34, "shortTasksCount": 14, "longTasksCount": 9, "postponementRatio": 2.5}'::jsonb,
        23,
        NOW() - INTERVAL '14 days',
        NOW(),
        'Moderate',
        'Active'
    ) ON CONFLICT (id) DO NOTHING;

    -- 8. Insert Active Experiment
    INSERT INTO public.experiments (id, user_id, insight_id, hypothesis, change_description, metric_definition, baseline_period_start, baseline_period_end, experiment_start, experiment_end, status)
    VALUES (
        'e0000000-0000-0000-0000-000000000001',
        demo_user_id,
        'i0000000-0000-0000-0000-000000000001',
        'Splitting heavy study blocks into 30-minute focused modules will raise completion rate to >= 75%',
        'Cap study sessions at 30 minutes with 5-minute cognitive resets between units',
        'Completion Rate = (Tasks Completed on Scheduled Day) / (Total Tasks Scheduled)',
        NOW() - INTERVAL '14 days',
        NOW(),
        NOW(),
        NOW() + INTERVAL '7 days',
        'Active'
    ) ON CONFLICT (id) DO NOTHING;

    -- 9. Insert Experiment Baseline Result
    INSERT INTO public.experiment_results (experiment_id, metric_name, baseline_value, result_value, sample_size, limitations)
    VALUES (
        'e0000000-0000-0000-0000-000000000001',
        'completion_rate',
        0.54,
        0.78,
        18,
        'Small sample size over 7 days. Correlation observed; external exam pressure may influence results.'
    ) ON CONFLICT DO NOTHING;

END $$;
