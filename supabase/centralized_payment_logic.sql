-- Centralized Payment Verification Logic
-- Run this in your Supabase SQL Editor

-- 1. Add rejection_reason column to payments table
ALTER TABLE payments ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- 2. Shared Function: Approve Payment
CREATE OR REPLACE FUNCTION approve_payment(
    p_payment_id UUID,
    p_processor_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_payment RECORD;
    v_payer_profile RECORD;
    v_current_expiry TIMESTAMP WITH TIME ZONE;
    v_added_months INTEGER;
    v_admin_setting RECORD;
BEGIN
    -- Fetch payment details
    SELECT * INTO v_payment FROM payments WHERE id = p_payment_id FOR UPDATE;
    
    IF v_payment IS NULL THEN
        RAISE EXCEPTION 'Payment not found';
    END IF;

    IF v_payment.status = 'approved' THEN
        RETURN;
    END IF;

    -- 1. Update Payment Status
    UPDATE payments 
    SET status = 'approved',
        processed_by = p_processor_id
    WHERE id = p_payment_id;

    -- 2. Notify Payer
    INSERT INTO notifications (user_id, title, message, type, link)
    VALUES (
        v_payment.user_id,
        'Payment Approved',
        'Your payment of ₦' || v_payment.amount || ' has been verified and approved.',
        'payment',
        '/patient/payments'
    );

    -- 3. Case A: Consultation Payment (has recipient_id and duration)
    IF v_payment.recipient_id IS NOT NULL AND v_payment.duration_minutes IS NOT NULL THEN
        -- Securely increment time balance
        PERFORM increment_time_balance(v_payment.user_id, v_payment.recipient_id, v_payment.duration_minutes);
        
        -- Notify Recipient (Doctor)
        INSERT INTO notifications (user_id, title, message, type, link)
        VALUES (
            v_payment.recipient_id,
            'Consultation Credit Verified',
            'A payment of ₦' || v_payment.amount || ' for ' || v_payment.duration_minutes || 'm has been verified.',
            'payment',
            '/doctor/dashboard'
        );
        
    -- 4. Case B: Platform Subscription (recipient_id is NULL)
    ELSIF v_payment.recipient_id IS NULL THEN
        SELECT * INTO v_payer_profile FROM profiles WHERE id = v_payment.user_id FOR UPDATE;

        IF v_payer_profile IS NOT NULL THEN
            -- Calculate new expiry
            v_current_expiry := COALESCE(v_payer_profile.subscription_expires_at, NOW());
            IF v_current_expiry < NOW() THEN
                v_current_expiry := NOW();
            END IF;
            
            -- If duration_minutes < 60, treat as "months", else default to 1 month
            v_added_months := CASE WHEN v_payment.duration_minutes < 60 THEN v_payment.duration_minutes ELSE 1 END;
            v_current_expiry := v_current_expiry + (v_added_months || ' months')::INTERVAL;

            -- Update Profile (Promote/Renew)
            UPDATE profiles
            SET role = 'doctor',
                subscription_status = 'active',
                fee_status = 'active',
                subscription_expires_at = v_current_expiry,
                last_subscription_payment_at = NOW(),
                verification_status = 'approved'
            WHERE id = v_payment.user_id;

            -- Notify Doctor
            INSERT INTO notifications (user_id, title, message, type, link)
            VALUES (
                v_payment.user_id,
                CASE WHEN v_payer_profile.role != 'doctor' THEN 'Account Formally Promoted' ELSE 'Subscription Renewed' END,
                'Professional dashboard is now active! Expires on ' || v_current_expiry::DATE,
                'system',
                '/doctor/dashboard'
            );

            -- 4b. Notify Admins of doctor activation
            FOR v_admin_setting IN SELECT * FROM admin_notification_settings LOOP
                IF 'doctor_verified' = ANY(v_admin_setting.alert_types) THEN
                    INSERT INTO notifications (user_id, title, message, type, link)
                    VALUES (
                        v_admin_setting.admin_id,
                        'Doctor Activation',
                        'Dr. ' || COALESCE(v_payer_profile.full_name, 'Unknown') || ' has been activated/renewed.',
                        'system',
                        '/admin/reports'
                    );
                END IF;
            END LOOP;
        END IF;
    END IF;

    -- Case A: Extra Admin Notifications for Consultation
    IF v_payment.recipient_id IS NOT NULL AND v_payment.duration_minutes IS NOT NULL THEN
        FOR v_admin_setting IN SELECT * FROM admin_notification_settings LOOP
            IF 'payment_verified' = ANY(v_admin_setting.alert_types) THEN
                INSERT INTO notifications (user_id, title, message, type, link)
                VALUES (
                    v_admin_setting.admin_id,
                    'Consultation Payment Verified',
                    'A payment of ₦' || v_payment.amount || ' for a ' || v_payment.duration_minutes || 'm session was verified.',
                    'payment',
                    '/admin/reports'
                );
            END IF;
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. View for Mobile Real-time Streaming (Standard Supabase streams don't support joins)
CREATE OR REPLACE VIEW pending_payments_view AS
SELECT 
    p.*,
    u.full_name as patient_name,
    u.avatar_url as patient_avatar
FROM payments p
JOIN profiles u ON p.user_id = u.id
WHERE p.status = 'pending';

-- Secure the view
ALTER VIEW pending_payments_view OWNER TO postgres;
GRANT SELECT ON pending_payments_view TO authenticated;



-- 3. Shared Function: Reject Payment
CREATE OR REPLACE FUNCTION reject_payment(
    p_payment_id UUID,
    p_reason TEXT,
    p_processor_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_payment RECORD;
BEGIN
    -- Fetch payment details
    SELECT * INTO v_payment FROM payments WHERE id = p_payment_id FOR UPDATE;
    
    IF v_payment IS NULL THEN
        RAISE EXCEPTION 'Payment not found';
    END IF;

    -- Update Payment Status
    UPDATE payments 
    SET status = 'rejected',
        rejection_reason = p_reason,
        processed_by = p_processor_id
    WHERE id = p_payment_id;

    -- Notify Payer
    INSERT INTO notifications (user_id, title, message, type, link)
    VALUES (
        v_payment.user_id,
        'Payment Rejected',
        'Your payment of ₦' || v_payment.amount || ' was rejected. Reason: ' || COALESCE(p_reason, 'No reason provided.'),
        'payment',
        '/patient/payments'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
