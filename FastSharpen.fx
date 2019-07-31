/*
   Fast Sharpen Shader
   
   Copyright (C) 2019 guest(r) - guest.r@gmail.com

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#include "ReShadeUI.fxh"
#include "ReShade.fxh" 
 

uniform float SHARPEN < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 2.0;
	ui_label = "Sharpen";
	ui_tooltip = "Sharpen intensity";
> = 0.9;

uniform float CONTRAST < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 0.20;
	ui_label = "Contrast";
	ui_tooltip = "Ammount of haloing etc.";
> = 0.045;

static const float2 g10 = float2( 0.35,-1.0)*ReShade::PixelSize;
static const float2 g01 = float2(-1.0,-0.35)*ReShade::PixelSize;
static const float2 g12 = float2(-0.35, 1.0)*ReShade::PixelSize;
static const float2 g21 = float2( 1.0, 0.35)*ReShade::PixelSize;

float3 SHARP (float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{		
	float3 c10 = tex2D(ReShade::BackBuffer, uv + g10).rgb;
	float3 c01 = tex2D(ReShade::BackBuffer, uv + g01).rgb;
	float3 c11 = tex2D(ReShade::BackBuffer, uv      ).rgb;
	float3 c21 = tex2D(ReShade::BackBuffer, uv + g21).rgb;
	float3 c12 = tex2D(ReShade::BackBuffer, uv + g12).rgb;

	float3 b11 = (c10+c01+c12+c21)*0.25;
	
	float contrast = lerp(2.0*CONTRAST, CONTRAST, max(max(c11.r, c11.g),c11.b));

	float3 mn1 = min(min(c10,c01),min(c12,c21)); mn1 = min(mn1,c11*(1.0-contrast));
	float3 mx1 = max(max(c10,c01),max(c12,c21)); mx1 = max(mx1,c11*(1.0+contrast));

	c11 = clamp(lerp(c11,b11,-SHARPEN), mn1,mx1); 
	
	return c11; 
} 

technique FastSharpen
{
	pass sharpen
	{
		VertexShader = PostProcessVS;
		PixelShader = SHARP;
	}	
}