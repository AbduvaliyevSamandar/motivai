"""initial tables

Revision ID: 001
Revises: 
Create Date: 2025-01-01
"""
from alembic import op
import sqlalchemy as sa

revision = '001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'users',
        sa.Column('id',              sa.Integer(),     primary_key=True, index=True),
        sa.Column('email',           sa.String(255),   unique=True, nullable=False),
        sa.Column('username',        sa.String(100),   unique=True, nullable=False),
        sa.Column('full_name',       sa.String(255),   nullable=False),
        sa.Column('hashed_password', sa.String(255),   nullable=False),
        sa.Column('faculty',         sa.String(100),   nullable=True),
        sa.Column('year',            sa.Integer(),     nullable=True),
        sa.Column('age',             sa.Integer(),     nullable=True),
        sa.Column('goal_type',       sa.String(50),    nullable=True),
        sa.Column('preferred_time',  sa.String(20),    nullable=True),
        sa.Column('gpa',             sa.Float(),       nullable=True),
        sa.Column('attendance_rate', sa.Float(),       nullable=True),
        sa.Column('daily_study_hours', sa.Float(),     nullable=True),
        sa.Column('sleep_hours',     sa.Float(),       nullable=True),
        sa.Column('stress_level',    sa.Integer(),     nullable=True),
        sa.Column('points',          sa.Integer(),     nullable=False, default=0),
        sa.Column('streak_days',     sa.Integer(),     nullable=False, default=0),
        sa.Column('level',           sa.Integer(),     nullable=False, default=1),
        sa.Column('badges',          sa.JSON(),        nullable=True),
        sa.Column('fcm_token',       sa.String(500),   nullable=True),
        sa.Column('notifications_enabled', sa.Boolean(), nullable=False, default=True),
        sa.Column('is_active',       sa.Boolean(),     nullable=False, default=True),
        sa.Column('last_active',     sa.DateTime(),    nullable=True),
        sa.Column('created_at',      sa.DateTime(),    server_default=sa.func.now()),
        sa.Column('updated_at',      sa.DateTime(),    server_default=sa.func.now()),
    )

    op.create_table(
        'motivation_logs',
        sa.Column('id',       sa.Integer(), primary_key=True, index=True),
        sa.Column('user_id',  sa.Integer(), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('date',     sa.DateTime(), server_default=sa.func.now()),
        sa.Column('motivation_level', sa.Integer(), nullable=True),
        sa.Column('stress_level',     sa.Integer(), nullable=True),
        sa.Column('mood_score',       sa.Integer(), nullable=True),
        sa.Column('energy_level',     sa.Integer(), nullable=True),
        sa.Column('ai_recommendations', sa.JSON(), nullable=True),
    )

    op.create_table(
        'task_completions',
        sa.Column('id',            sa.Integer(),     primary_key=True, index=True),
        sa.Column('user_id',       sa.Integer(),     sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('task_key',      sa.String(50),    nullable=True),
        sa.Column('task_title',    sa.String(255),   nullable=True),
        sa.Column('points_earned', sa.Integer(),     nullable=True),
        sa.Column('completed_at',  sa.DateTime(),    server_default=sa.func.now()),
    )


def downgrade() -> None:
    op.drop_table('task_completions')
    op.drop_table('motivation_logs')
    op.drop_table('users')
