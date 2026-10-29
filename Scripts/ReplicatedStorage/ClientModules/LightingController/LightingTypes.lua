-- OmniRal

local LightingTypes = {}

export type LightingSetting = {
	Lighting: {
		Ambient: Color3?,
		Brightness: number?,
		ColorShift_Bottom: Color3?,
		ColorShift_Top: Color3?,
		EnvironmentDiffuseScale: number?,
		EnvironmentSpecularScale: number?,
		OutdoorAmbient: Color3?,
		ClockTime: number?,
		GeographicLatitude: number?,
		ExposureCompensation: number?,
	}?,

	Atmosphere: {
		Density: number?, 
		Offset: number?,
		Color: Color3?,
		Decay: Color3?,
		Glare: number?,
		Haze: number?,
	}?,

	Bloom: {
		Enabled: boolean?,
		Intensity: number?,
		Size: number?,
		Threshold: number?,
	}?,

	Blur: {
		Enabled: boolean?,
		Size: number?,
	}?,

	ColorCorrection: {
		Enabled: boolean?,
		Brightness: number?,
		Contrast: number?,
		Saturation: number?,
		TintColor: Color3?,
	}?,

	DepthOfField: {
		Enabled: boolean?,
		FarIntensity: number?,
		FocusDistance: number?,
		InFocusRadius: number?,
		NearIntensity: number?,
	}?,

	SunRays: {
		Enabled: boolean?,
		Intensity: number?,
		Spread: number?
	}?
}

return LightingTypes