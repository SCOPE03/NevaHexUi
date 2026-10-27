--[[
	NEVAHEXUI - Themes/Defs
	Built-in theme catalogue. Every theme is a real token set validated by
	Themes/Registry; token tables are partial and are merged over Tokens.Defaults.
	The default accent colour across the framework is NEVA red (#EF4444).
]]

local Defs = {}

local DEFAULT_ACCENT = "#EF4444"

Defs.List = {
	{
		Id = "dark",
		Name = "Dark",
		Category = "Core",
		Description = "The framework default: neutral charcoal surfaces with the NEVA red accent.",
		Tokens = {
			Background = "#101014", Surface = "#17171E", SurfaceAlt = "#1F1F2A", Outline = "#2E2E3C",
			Text = "#F4F4F7", TextMuted = "#9C9CAC", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			Positive = "#3DDC97", Warning = "#F5A524", Negative = "#FF5470",
			CornerRadius = 8, BackgroundTransparency = 0.06, SurfaceTransparency = 0.12,
		},
	},
	{
		Id = "neva",
		Name = "NEVA",
		Category = "Core",
		Description = "Signature NEVA palette: deep red-tinted surfaces with a hot accent.",
		Tokens = {
			Background = "#120A0C", Surface = "#1B0F12", SurfaceAlt = "#26151A", Outline = "#3D2026",
			Text = "#FFF3F4", TextMuted = "#C39AA0", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			Positive = "#4ADE80", Warning = "#FBBF24", Negative = "#FB7185",
			CornerRadius = 10, BackgroundTransparency = 0.04, SurfaceTransparency = 0.08, AnimationDuration = 0.2,
		},
	},
	{
		Id = "light",
		Name = "Light",
		Category = "Core",
		Description = "Light neutral surfaces with strong text contrast.",
		Tokens = {
			Background = "#F5F5F7", Surface = "#FFFFFF", SurfaceAlt = "#ECECF1", Outline = "#D3D3DC",
			Text = "#16161C", TextMuted = "#5C5C6B", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			Positive = "#0F9D63", Warning = "#B4690E", Negative = "#D92D5B",
			CornerRadius = 8, BackgroundTransparency = 0, SurfaceTransparency = 0,
		},
	},
	{
		Id = "modern",
		Name = "Modern",
		Category = "Styled",
		Description = "Large radii, generous spacing and soft elevation.",
		Tokens = {
			Background = "#0E1116", Surface = "#161B22", SurfaceAlt = "#1E242D", Outline = "#2B323D",
			Text = "#E6EDF3", TextMuted = "#8B949E", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			CornerRadius = 14, Padding = 12, Spacing = 10, BackgroundTransparency = 0.03,
		},
	},
	{
		Id = "minimal",
		Name = "Minimal",
		Category = "Styled",
		Description = "Flat surfaces, hairline outlines and no elevation.",
		Tokens = {
			Background = "#0C0C0E", Surface = "#131316", SurfaceAlt = "#191920", Outline = "#26262E",
			Text = "#EDEDF2", TextMuted = "#8A8A99", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			CornerRadius = 2, StrokeThickness = 1, Spacing = 6, BackgroundTransparency = 0,
			SurfaceTransparency = 0, AnimationDuration = 0.12,
		},
	},
	{
		Id = "classic",
		Name = "Classic",
		Category = "Styled",
		Description = "Squared corners and grey panels reminiscent of first-generation UIs.",
		Tokens = {
			Background = "#1B1B1B", Surface = "#262626", SurfaceAlt = "#333333", Outline = "#4D4D4D",
			Text = "#FFFFFF", TextMuted = "#A6A6A6", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			CornerRadius = 0, StrokeThickness = 1, Font = "SourceSans", FontBold = "SourceSansBold",
			BackgroundTransparency = 0, SurfaceTransparency = 0,
		},
	},
	{
		Id = "glass",
		Name = "Glass",
		Category = "Styled",
		Description = "High-transparency panels designed to sit over 3D content.",
		Tokens = {
			Background = "#0A0F18", Surface = "#121926", SurfaceAlt = "#1A2333", Outline = "#3A4A66",
			Text = "#F0F6FF", TextMuted = "#9FB0C7", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			CornerRadius = 16, BackgroundTransparency = 0.35, SurfaceTransparency = 0.4,
			AccentTransparency = 0.1, StrokeThickness = 1,
		},
	},
	{
		Id = "acrylic",
		Name = "Acrylic",
		Category = "Styled",
		Description = "Translucent blue-grey material with a soft rim light.",
		Tokens = {
			Background = "#141A22", Surface = "#1D2632", SurfaceAlt = "#27323F", Outline = "#42546B",
			Text = "#F2F7FD", TextMuted = "#A3B4C9", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			CornerRadius = 12, BackgroundTransparency = 0.28, SurfaceTransparency = 0.32,
		},
	},
	{
		Id = "neon",
		Name = "Neon",
		Category = "Expressive",
		Description = "Saturated accents on near-black surfaces with fast transitions.",
		Tokens = {
			Background = "#05050A", Surface = "#0B0B16", SurfaceAlt = "#12122A", Outline = "#2A2A5C",
			Text = "#EAEAFE", TextMuted = "#8A8AC8", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			Positive = "#39FF14", Warning = "#FFD300", Negative = "#FF2E63",
			CornerRadius = 6, AnimationDuration = 0.16, Easing = "Cubic",
		},
	},
	{
		Id = "voltage",
		Name = "Voltage",
		Category = "Expressive",
		Description = "Electric yellow accent with hard outlines.",
		Tokens = {
			Background = "#0B0B0B", Surface = "#151515", SurfaceAlt = "#1F1F1F", Outline = "#3A3A00",
			Text = "#FFFBE6", TextMuted = "#BDB68A", Accent = "#FACC15", AccentText = "#0B0B0B",
			Positive = "#A3E635", Warning = "#FB923C", Negative = "#EF4444",
			CornerRadius = 4, StrokeThickness = 2,
		},
	},
	{
		Id = "terminal",
		Name = "Terminal",
		Category = "Expressive",
		Description = "Monospace green-on-black console styling.",
		Tokens = {
			Background = "#000600", Surface = "#02120A", SurfaceAlt = "#04200F", Outline = "#0C3A1C",
			Text = "#8CFFB0", TextMuted = "#3FA968", Accent = "#3EE07F", AccentText = "#001A0A",
			Positive = "#3EE07F", Warning = "#E0D33E", Negative = "#E03E5A",
			CornerRadius = 0, Font = "Code", FontBold = "Code", AnimationDuration = 0.08,
			BackgroundTransparency = 0, SurfaceTransparency = 0,
		},
	},
	{
		Id = "highcontrast",
		Name = "High Contrast",
		Category = "Accessible",
		Description = "Maximum contrast for accessibility and readability.",
		Tokens = {
			Background = "#000000", Surface = "#0A0A0A", SurfaceAlt = "#141414", Outline = "#FFFFFF",
			Text = "#FFFFFF", TextMuted = "#D6D6D6", Accent = "#FF3B30", AccentText = "#FFFFFF",
			Positive = "#00FF7F", Warning = "#FFD400", Negative = "#FF1744",
			CornerRadius = 4, StrokeThickness = 2, FontSize = 14, BackgroundTransparency = 0,
			SurfaceTransparency = 0, AnimationDuration = 0.1,
		},
	},
	{
		Id = "paper",
		Name = "Paper",
		Category = "Accessible",
		Description = "Warm off-white paper surfaces with ink text.",
		Tokens = {
			Background = "#F7F3EA", Surface = "#FFFDF7", SurfaceAlt = "#EFE8DA", Outline = "#D6CBB5",
			Text = "#2A2418", TextMuted = "#6E6250", Accent = "#C2410C", AccentText = "#FFFFFF",
			Positive = "#15803D", Warning = "#B45309", Negative = "#B91C1C",
			CornerRadius = 6, BackgroundTransparency = 0, SurfaceTransparency = 0,
		},
	},
	{
		Id = "ocean",
		Name = "Ocean",
		Category = "Expressive",
		Description = "Deep teal depth with cyan highlights.",
		Tokens = {
			Background = "#04202B", Surface = "#07303F", SurfaceAlt = "#0B3F52", Outline = "#15607A",
			Text = "#E6FBFF", TextMuted = "#8FBFCC", Accent = "#22D3EE", AccentText = "#04202B",
			Positive = "#34D399", Warning = "#FBBF24", Negative = "#FB7185",
			CornerRadius = 10, BackgroundTransparency = 0.05,
		},
	},
	{
		Id = "grape",
		Name = "Grape",
		Category = "Expressive",
		Description = "Violet surfaces with a magenta accent.",
		Tokens = {
			Background = "#150A24", Surface = "#1F1035", SurfaceAlt = "#2B1747", Outline = "#4A2A78",
			Text = "#F5EDFF", TextMuted = "#B49AD6", Accent = "#D946EF", AccentText = "#FFFFFF",
			Positive = "#4ADE80", Warning = "#FCD34D", Negative = "#FB7185",
			CornerRadius = 10,
		},
	},
	{
		Id = "blood",
		Name = "Blood",
		Category = "Expressive",
		Description = "Dark crimson palette with a bright red accent.",
		Tokens = {
			Background = "#150505", Surface = "#210A0A", SurfaceAlt = "#2E1010", Outline = "#5C1A1A",
			Text = "#FFEDED", TextMuted = "#C58B8B", Accent = "#FF2D2D", AccentText = "#FFFFFF",
			Positive = "#65A30D", Warning = "#D97706", Negative = "#FF4D6D",
			CornerRadius = 6,
		},
	},
	{
		Id = "abyss",
		Name = "Abyss",
		Category = "Core",
		Description = "Very dark blue-black surfaces for low-light environments.",
		Tokens = {
			Background = "#04060D", Surface = "#0A0F1A", SurfaceAlt = "#111827", Outline = "#1F2A3D",
			Text = "#E2E8F5", TextMuted = "#7C8AA5", Accent = DEFAULT_ACCENT, AccentText = "#FFFFFF",
			Positive = "#34D399", Warning = "#F59E0B", Negative = "#F43F5E",
			CornerRadius = 8, BackgroundTransparency = 0.1,
		},
	},
	{
		Id = "midnight",
		Name = "Midnight",
		Category = "Core",
		Description = "Blue-tinted midnight surfaces with muted accents.",
		Tokens = {
			Background = "#0B1020", Surface = "#131A2E", SurfaceAlt = "#1B2440", Outline = "#2E3A5C",
			Text = "#EEF2FF", TextMuted = "#94A3C4", Accent = "#6366F1", AccentText = "#FFFFFF",
			Positive = "#22C55E", Warning = "#EAB308", Negative = "#EF4444",
			CornerRadius = 12,
		},
	},
	{
		Id = "marshmallow",
		Name = "Marshmallow",
		Category = "Expressive",
		Description = "Soft pastel surfaces with pink accents.",
		Tokens = {
			Background = "#FFF1F6", Surface = "#FFFFFF", SurfaceAlt = "#FFE4EE", Outline = "#F7C2D8",
			Text = "#3B1E2C", TextMuted = "#8A5D72", Accent = "#F472B6", AccentText = "#FFFFFF",
			Positive = "#10B981", Warning = "#F59E0B", Negative = "#E11D48",
			CornerRadius = 16, BackgroundTransparency = 0, SurfaceTransparency = 0,
		},
	},
	{
		Id = "ember",
		Name = "Ember",
		Category = "Expressive",
		Description = "Charcoal surfaces with a warm amber accent.",
		Tokens = {
			Background = "#141010", Surface = "#1E1815", SurfaceAlt = "#2A211C", Outline = "#453529",
			Text = "#FFF4E8", TextMuted = "#BFA98C",
			Accent = "#F97316", AccentText = "#1A0F05",
			CornerRadius = 8, Easing = "Sine",
		},
	},
	{
		Id = "cassette",
		Name = "Cassette",
		Category = "Expressive",
		Description = "Retro plastic grey with teal and orange highlights.",
		Tokens = {
			Background = "#20232A", Surface = "#2B2F38", SurfaceAlt = "#363B46", Outline = "#4C5361",
			Text = "#F2F5F9", TextMuted = "#A6AEBD", Accent = "#14B8A6", AccentText = "#04211E",
			Positive = "#22C55E", Warning = "#F59E0B", Negative = "#EF4444",
			CornerRadius = 4, Font = "SourceSans",
		},
	},
}

return Defs
