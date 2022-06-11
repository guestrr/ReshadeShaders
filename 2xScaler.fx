/*  
   2D-Scaler for ReShade
   
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


uniform float o < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.25; ui_max = 2.0;
	ui_label = "Filter Width";
	ui_tooltip = "Filter Width";
> = 1.0; 

uniform float DBL < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.0; ui_max = 5.0;
	ui_label = "Deblur";
	ui_tooltip = "Deblur strength";
> = 2.5; 

texture Texture02 { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler Texture02S { Texture = Texture02; }; 


float3 texture2d (float2 texcoord, float4 yx) {
	float3 dt = float3(1.0,1.0,1.0);

	float3 s00 = tex2D(ReShade::BackBuffer,texcoord + yx.zw).xyz; 
	float3 s20 = tex2D(ReShade::BackBuffer,texcoord + yx.xw).xyz; 
	float3 s22 = tex2D(ReShade::BackBuffer,texcoord + yx.xy).xyz; 
	float3 s02 = tex2D(ReShade::BackBuffer,texcoord + yx.zy).xyz; 

	float m1=dot(abs(s00-s22),dt)+0.001;
	float m2=dot(abs(s02-s20),dt)+0.001;

	return .5*(m2*(s00+s22)+m1*(s02+s20))/(m1+m2);
}

float3 TWODS0(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	float3 dt = float3(1.0,1.0,1.0);

	// Calculating texel coordinates
	float2 inv_size = o * ReShade::PixelSize;	
	float2 size     = 1.0/inv_size;

	float4 yx = float4(inv_size, -inv_size);
	
	float2 OGL2Pos = uv*size;
	float2 fp = frac(OGL2Pos);
	float2 dx = float2(inv_size.x,0.0);
	float2 dy = float2(0.0, inv_size.y);
	float2 g1 = float2(inv_size.x,inv_size.y);
	float2 g2 = float2(-inv_size.x,inv_size.y);
	
	float2 pC4 = floor(OGL2Pos) * inv_size + 0.5 * inv_size;
	
	// Reading the texels
	float3 C0 = texture2d(pC4 - g1, yx); 
	float3 C1 = texture2d(pC4 - dy, yx);
	float3 C2 = texture2d(pC4 - g2, yx);
	float3 C3 = texture2d(pC4 - dx, yx);
	float3 C4 = texture2d(pC4     , yx);
	float3 C5 = texture2d(pC4 + dx, yx);
	float3 C6 = texture2d(pC4 + g2, yx);
	float3 C7 = texture2d(pC4 + dy, yx);
	float3 C8 = texture2d(pC4 + g1, yx);
	
	float3 ul, ur, dl, dr;
	float m1, m2;
	
	m1 = dot(abs(C0-C4),dt)+0.001;
	m2 = dot(abs(C1-C3),dt)+0.001;
	ul = (m2*(C0+C4)+m1*(C1+C3))/(m1+m2);  
	
	m1 = dot(abs(C1-C5),dt)+0.001;
	m2 = dot(abs(C2-C4),dt)+0.001;
	ur = (m2*(C1+C5)+m1*(C2+C4))/(m1+m2);
	
	m1 = dot(abs(C3-C7),dt)+0.001;
	m2 = dot(abs(C6-C4),dt)+0.001;
	dl = (m2*(C3+C7)+m1*(C6+C4))/(m1+m2);
	
	m1 = dot(abs(C4-C8),dt)+0.001;
	m2 = dot(abs(C5-C7),dt)+0.001;
	dr = (m2*(C4+C8)+m1*(C5+C7))/(m1+m2);
	
	float3 c11 = 0.5*((dr*fp.x+dl*(1-fp.x))*fp.y+(ur*fp.x+ul*(1-fp.x))*(1-fp.y));
	
	return c11;
}


float3 DEB(float4 pos : SV_Position, float2 uv1 : TexCoord) : SV_Target
{
	// Calculating texel coordinates
	float2 inv_size = 1.375 * o * ReShade::PixelSize;	
	float2 size     = 1.0/inv_size;

	float2 dx = float2(inv_size.x,0.0);
	float2 dy = float2(0.0, inv_size.y);
	float2 g1 = float2(inv_size.x,inv_size.y);
	float2 g2 = float2(-inv_size.x,inv_size.y);
	
	float2 pC4 = uv1;	
	
	// Reading the texels
	float3 c00 = tex2D(Texture02S,pC4 - g1).rgb; 
	float3 c10 = tex2D(Texture02S,pC4 - dy).rgb;
	float3 c20 = tex2D(Texture02S,pC4 - g2).rgb;
	float3 c01 = tex2D(Texture02S,pC4 - dx).rgb;
	float3 c11 = tex2D(Texture02S,pC4     ).rgb;
	float3 c21 = tex2D(Texture02S,pC4 + dx).rgb;
	float3 c02 = tex2D(Texture02S,pC4 + g2).rgb;
	float3 c12 = tex2D(Texture02S,pC4 + dy).rgb;
	float3 c22 = tex2D(Texture02S,pC4 + g1).rgb;
	
	float3 d11 = c11;

	float3 mn1 = min (min (c00,c01),c02);
	float3 mn2 = min (min (c10,c11),c12);
	float3 mn3 = min (min (c20,c21),c22);
	float3 mx1 = max (max (c00,c01),c02);
	float3 mx2 = max (max (c10,c11),c12);
	float3 mx3 = max (max (c20,c21),c22);
   
	mn1 = min(min(mn1,mn2),mn3);
	mx1 = max(max(mx1,mx2),mx3);

	float3 dif1 = abs(c11-mn1) + 0.0001;
	float3 dif2 = abs(c11-mx1) + 0.0001;
   
	float3 dt = float3(1.0,1.0,1.0);
	float d1=dot(abs(c00-c22),dt)+0.0001;
	float d2=dot(abs(c20-c02),dt)+0.0001;
	float hl=dot(abs(c01-c21),dt)+0.0001;
	float vl=dot(abs(c10-c12),dt)+0.0001;

	float dif = pow(max(d1+d2+hl+vl-0.2,0.0)/(0.25*dot(c01+c10+c12+c21,dt)+0.33),0.75);
   
	dif = min(dif, 1.0);
	float DB1 = max(lerp( 0.0, DBL, dif), 1.0);
   
	dif1=float3(pow(dif1.x,DB1),pow(dif1.y,DB1),pow(dif1.z,DB1));
	dif2=float3(pow(dif2.x,DB1),pow(dif2.y,DB1),pow(dif2.z,DB1));

	d11 = float3((dif1.x*mx1.x + dif2.x*mn1.x)/(dif1.x + dif2.x),
				(dif1.y*mx1.y + dif2.y*mn1.y)/(dif1.y + dif2.y),
				(dif1.z*mx1.z + dif2.z*mn1.z)/(dif1.z + dif2.z));   
		
	float k10 = 1.0/(dot(abs(c10-d11),dt)+0.0001);
	float k01 = 1.0/(dot(abs(c01-d11),dt)+0.0001);
	float k11 = 1.0/(dot(abs(c11-d11),dt)+0.0001);  
	float k21 = 1.0/(dot(abs(c21-d11),dt)+0.0001);
	float k12 = 1.0/(dot(abs(c12-d11),dt)+0.0001);   
	float k00 = 1.0/(dot(abs(c00-d11),dt)+0.0001);
	float k02 = 1.0/(dot(abs(c02-d11),dt)+0.0001);  
	float k20 = 1.0/(dot(abs(c20-d11),dt)+0.0001);
	float k22 = 1.0/(dot(abs(c22-d11),dt)+0.0001);   
   
	float avg = 0.025*(k10+k01+k11+k21+k12+k00+k02+k20+k22);
   
	k10 = max(k10-avg, 0.0);
	k01 = max(k01-avg, 0.0);
	k11 = max(k11-avg, 0.0);   
	k21 = max(k21-avg, 0.0);
	k12 = max(k12-avg, 0.0);
	k00 = max(k00-avg, 0.0);
	k02 = max(k02-avg, 0.0);   
	k20 = max(k20-avg, 0.0);
	k22 = max(k22-avg, 0.0);
   
	c11 = (k10*c10 + k01*c01 + k11*c11 + k21*c21 + k12*c12 + k00*c00 + k02*c02 + k20*c20 + k22*c22 + 0.0001*c11)/(k10+k01+k11+k21+k12+k00+k02+k20+k22+0.0001);
	
	return c11;
} 


technique TWO_D_SCALER
{
	pass twod1
	{
		VertexShader = PostProcessVS;
		PixelShader = TWODS0;
		RenderTarget = Texture02; 		
	}
	pass twod2
	{
		VertexShader = PostProcessVS;
		PixelShader = DEB;
	}	
} 