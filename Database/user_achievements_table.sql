-- ===================================
-- 成就系统数据库表
-- AIRunningCoach v1.0
-- ===================================

-- 创建 user_achievements 表
CREATE TABLE IF NOT EXISTS user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_id TEXT NOT NULL,
    current_value DOUBLE PRECISION NOT NULL DEFAULT 0,
    is_unlocked BOOLEAN NOT NULL DEFAULT FALSE,
    unlocked_at TIMESTAMP WITH TIME ZONE,
    shared_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- 确保每个用户的每个成就只有一条记录
    UNIQUE(user_id, achievement_id)
);

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON user_achievements(achievement_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_is_unlocked ON user_achievements(is_unlocked);
CREATE INDEX IF NOT EXISTS idx_user_achievements_unlocked_at ON user_achievements(unlocked_at DESC);

-- 启用 Row Level Security (RLS)
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- 创建 RLS 策略：用户只能访问自己的成就数据
CREATE POLICY "Users can view their own achievements"
    ON user_achievements
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own achievements"
    ON user_achievements
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own achievements"
    ON user_achievements
    FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own achievements"
    ON user_achievements
    FOR DELETE
    USING (auth.uid() = user_id);

-- 创建触发器：自动更新 updated_at 字段
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_achievements_updated_at
    BEFORE UPDATE ON user_achievements
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===================================
-- 成就统计视图（可选）
-- ===================================

-- 创建视图：用户成就统计
CREATE OR REPLACE VIEW user_achievement_stats AS
SELECT
    user_id,
    COUNT(*) AS total_achievements,
    COUNT(*) FILTER (WHERE is_unlocked = TRUE) AS unlocked_count,
    SUM(shared_count) AS total_shares,
    MAX(unlocked_at) AS last_unlock_date
FROM user_achievements
GROUP BY user_id;

-- 授予查询权限
GRANT SELECT ON user_achievement_stats TO authenticated;

-- ===================================
-- 示例查询
-- ===================================

-- 查询用户所有已解锁的成就
-- SELECT * FROM user_achievements WHERE user_id = '...' AND is_unlocked = TRUE ORDER BY unlocked_at DESC;

-- 查询用户成就统计
-- SELECT * FROM user_achievement_stats WHERE user_id = '...';

-- 查询最近解锁的成就（全局排行）
-- SELECT ua.*, u.email FROM user_achievements ua
-- JOIN auth.users u ON ua.user_id = u.id
-- WHERE ua.is_unlocked = TRUE
-- ORDER BY ua.unlocked_at DESC
-- LIMIT 10;

-- ===================================
-- 完成！
-- ===================================
