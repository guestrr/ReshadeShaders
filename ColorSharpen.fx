/*
   Color Sharpen shader
   
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
> = 0.8;

uniform float CONTRAST < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 0.20;
	ui_label = "Contrast";
	ui_tooltip = "Ammount of haloing etc.";
> = 0.05;

 
float3 GetWeight1(float3 dif1)
{
	return clamp(-0.86666666666667*dif1 + 0.71666666666667, 0.07, 0.5);
}

float3 GetWeight2(float3 dif2)
{
	return clamp(-0.52*dif2 + 0.43, 0.042, 0.3);
}
 
float3 SHARP(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	// Reading the texels

	float3 c10 = tex2Doffset(ReShade::BackBuffer, uv, int2( 0,-1)).rgb;
	float3 c01 = tex2Doffset(ReShade::BackBuffer, uv, int2(-1, 0)).rgb;
	float3 c11 = tex2Doffset(ReShade::BackBuffer, uv, int2( 0, 0)).rgb;
	float3 c21 = tex2Doffset(ReShade::BackBuffer, uv, int2( 1, 0)).rgb;
	float3 c12 = tex2Doffset(ReShade::BackBuffer, uv, int2( 0, 1)).rgb;
	float3 c00 = tex2Doffset(ReShade::BackBuffer, uv, int2(-1,-1)).rgb;
	float3 c20 = tex2Doffset(ReShade::BackBuffer, uv, int2( 1,-1)).rgb;
	float3 c02 = tex2Doffset(ReShade::BackBuffer, uv, int2(-1, 1)).rgb;
	float3 c22 = tex2Doffset(ReShade::BackBuffer, uv, int2( 1, 1)).rgb;	
	
	float3 w10 = GetWeight1(abs(c11-c10));
	float3 w01 = GetWeight1(abs(c11-c01));
	float3 w21 = GetWeight1(abs(c11-c21));
	float3 w12 = GetWeight1(abs(c11-c12));
	float3 w00 = GetWeight2(abs(c11-c00));
	float3 w20 = GetWeight2(abs(c11-c20));
	float3 w02 = GetWeight2(abs(c11-c02));
	float3 w22 = GetWeight2(abs(c11-c22));
	
	float contrast = max(max(c11.r,c11.g),c11.b);
	contrast = lerp(2.0*CONTRAST, CONTRAST, contrast);
	
	float3 mn1 = min(min(c10,c01),min(c12,c21)); mn1 = min(mn1,c11*(1.0-contrast));
	float3 mx1 = max(max(c10,c01),max(c12,c21)); mx1 = max(mx1,c11*(1.0+contrast));
		
	float3 wsum = w10+w01+w21+w12+w00+w20+w02+w22;
	float3 scol = (w10*c10+w01*c01+w21*c21+w12*c12+w00*c00+w20*c20+w02*c02+w22*c22)/wsum;
	
	c11 = clamp(lerp(c11,scol,-SHARPEN), mn1,mx1); 
	
	return c11;
}

technique ColorSharpen
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = SHARP;
	}
}
