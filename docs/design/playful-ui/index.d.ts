import type * as React from 'react';
export type Tone = 'coral' | 'teal' | 'mustard' | 'orange' | 'lavender';
export type IconName = 'arrow-right' | 'arrow-left' | 'external' | 'home' | 'book' | 'chart' | 'trophy' | 'settings' | 'bell' | 'play' | 'star' | 'cap' | 'check';
export interface IconProps { name: IconName; size?: number; className?: string }
export declare function Icon(props: IconProps): React.ReactElement;
export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> { variant?: 'dark' | 'light' | 'soft' | 'teal' | 'coral' | 'ghost'; size?: 'md' | 'sm'; icon?: IconName }
export declare function Button(props: ButtonProps): React.ReactElement;
export interface IconButtonProps { icon?: IconName; label: string; tone?: 'light' | 'soft' | 'dark' | 'ghost' | 'outline'; size?: number; onClick?: () => void; disabled?: boolean; className?: string }
export declare function IconButton(props: IconButtonProps): React.ReactElement;
export interface SegmentedControlProps { options: { value: string; label: string }[]; value?: string; onChange?: (value: string) => void; tone?: 'light' | 'teal' | 'peach'; label?: string; className?: string }
export declare function SegmentedControl(props: SegmentedControlProps): React.ReactElement;
export interface ChipProps { tone?: 'neutral' | 'light' | Tone; icon?: IconName; selected?: boolean; onClick?: () => void; children?: React.ReactNode; className?: string }
export declare function Chip(props: ChipProps): React.ReactElement;
export interface StatTileProps { value: React.ReactNode; unit?: string; label: string; icon?: IconName; tone?: 'neutral' | Tone; dashed?: boolean; className?: string }
export declare function StatTile(props: StatTileProps): React.ReactElement;
export type Person = string | { name: string; src?: string };
export interface AvatarStackProps { people: Person[]; max?: number; total?: number; size?: number; className?: string }
export declare function AvatarStack(props: AvatarStackProps): React.ReactElement;
export interface CourseCardProps { title: string; eyebrow?: string; icon?: IconName; tone?: 'night' | 'lavender' | 'coral' | 'orange'; people?: Person[]; total?: number; actionLabel?: string; onOpen?: () => void; className?: string }
export declare function CourseCard(props: CourseCardProps): React.ReactElement;
export interface LeaderboardRowProps { rank: number; score: number; name: Person; tone?: 'coral' | 'mustard' | 'light' | 'teal'; className?: string }
export declare function LeaderboardRow(props: LeaderboardRowProps): React.ReactElement;
export interface BottomNavProps { items: { value: string; label: string; icon: IconName }[]; value?: string; onChange?: (value: string) => void; label?: string; className?: string }
export declare function BottomNav(props: BottomNavProps): React.ReactElement;
declare global { interface Window { PlayfulUI: { Button: typeof Button; IconButton: typeof IconButton; SegmentedControl: typeof SegmentedControl; Chip: typeof Chip; StatTile: typeof StatTile; CourseCard: typeof CourseCard; LeaderboardRow: typeof LeaderboardRow; AvatarStack: typeof AvatarStack; BottomNav: typeof BottomNav; Icon: typeof Icon; Mascot: typeof Mascot } } }
export type MascotMood = 'idle' | 'happy' | 'celebrate' | 'thinking' | 'oops' | 'sad' | 'sleepy' | 'love';
export interface MascotProps { mood?: MascotMood; size?: number; animated?: boolean; title?: string; className?: string }
export declare function Mascot(props: MascotProps): React.ReactElement;
