/*  
   2D-Scaler Level2 shader for ReShade
   
   Copyright (C) 2019 guest(r)

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
	ui_min = 0.10; ui_max = 2.0; ui_step = 0.05; 
	ui_label = "Filter Width";
	ui_tooltip = "Filter Width";
> = 1.0; 

uniform float DBL < __UNIFORM_SLIDER_FLOAT1
	ui_min = 1.0; ui_max = 8.0; ui_step = 0.10; 
	ui_label = "Deblur";
	ui_tooltip = "Deblur strength";
> = 2.5; 

uniform float SMART < __UNIFORM_SLIDER_FLOAT1
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Smart Deblur";
	ui_tooltip = "Smart Deblur intensity";
> = 0.5; 

texture Texture01L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler Texture01SL { Texture = Texture01L; MinFilter = Linear; MagFilter = Linear; }; 

texture Texture02L  { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler Texture02SL { Texture = Texture02L; MinFilter = Linear; MagFilter = Linear; }; 


float3 TWODS0(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
{
	float2 inv_size = o * ReShade::PixelSize;	

	float dx = inv_size.x;
	float dy = inv_size.y;
	
    float4 yx = float4(dx, dy, -dx, -dy);
    float4 xh = yx*float4(3.0, 1.0, 3.0, 1.0);
    float4 yv = yx*float4(1.0, 3.0, 1.0, 3.0);
	float3 dt = 1.0.xxx;

    float3 c11 = tex2D(ReShade::BackBuffer, uv        ).xyz;    
    float3 s00 = tex2D(ReShade::BackBuffer, uv + yx.zw).xyz; 
    float3 s20 = tex2D(ReShade::BackBuffer, uv + yx.xw).xyz; 
    float3 s22 = tex2D(ReShade::BackBuffer, uv + yx.xy).xyz; 
    float3 s02 = tex2D(ReShade::BackBuffer, uv + yx.zy).xyz;
    float3 h00 = tex2D(ReShade::BackBuffer, uv + xh.zw).xyz; 
    float3 h20 = tex2D(ReShade::BackBuffer, uv + xh.xw).xyz; 
    float3 h22 = tex2D(ReShade::BackBuffer, uv + xh.xy).xyz; 
    float3 h02 = tex2D(ReShade::BackBuffer, uv + xh.zy).xyz;
    float3 v00 = tex2D(ReShade::BackBuffer, uv + yv.zw).xyz; 
    float3 v20 = tex2D(ReShade::BackBuffer, uv + yv.xw).xyz; 
    float3 v22 = tex2D(ReShade::BackBuffer, uv + yv.xy).xyz; 
    float3 v02 = tex2D(ReShade::BackBuffer, uv + yv.zy).xyz;     

    float m1 = 1.0/(dot(abs(s00 - s22), dt) + 0.00001);
    float m2 = 1.0/(dot(abs(s02 - s20), dt) + 0.00001);
    float h1 = 1.0/(dot(abs(s00 - h22), dt) + 0.00001);
    float h2 = 1.0/(dot(abs(s02 - h20), dt) + 0.00001);
    float h3 = 1.0/(dot(abs(h00 - s22), dt) + 0.00001);
    float h4 = 1.0/(dot(abs(h02 - s20), dt) + 0.00001);
    float v1 = 1.0/(dot(abs(s00 - v22), dt) + 0.00001);
    float v2 = 1.0/(dot(abs(s02 - v20), dt) + 0.00001);
    float v3 = 1.0/(dot(abs(v00 - s22), dt) + 0.00001);
    float v4 = 1.0/(dot(abs(v02 - s20), dt) + 0.00001);

    float3 t1 = 0.5*(m1*(s00 + s22) + m2*(s02 + s20))/(m1 + m2);
    float3 t2 = 0.5*(h1*(s00 + h22) + h2*(s02 + h20) + h3*(h00 + s22) + h4*(h02 + s20))/(h1 + h2 + h3 + h4);
    float3 t3 = 0.5*(v1*(s00 + v22) + v2*(s02 + v20) + v3*(v00 + s22) + v4*(v02 + s20))/(v1 + v2 + v3 + v4);

    float k1 = 1.0/(dot(abs(t1 - c11), dt) + 0.00001);
    float k2 = 1.0/(dot(abs(t2 - c11), dt) + 0.00001);
    float k3 = 1.0/(dot(abs(t3 - c11), dt) + 0.00001);

    c11 = (k1*t1 + k2*t2 + k3*t3)/(k1 + k2 + k3);

	return c11;
}

float3 TWODS1(float4 pos : SV_Position, float2 uv : TexCoord) : SV_Target
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
	float3 C0 = tex2D(Texture01SL, pC4 - g1).rgb; 
	float3 C1 = tex2D(Texture01SL, pC4 - dy).rgb;
	float3 C2 = tex2D(Texture01SL, pC4 - g2).rgb;
	float3 C3 = tex2D(Texture01SL, pC4 - dx).rgb;
	float3 C4 = tex2D(Texture01SL, pC4     ).rgb;
	float3 C5 = tex2D(Texture01SL, pC4 + dx).rgb;
	float3 C6 = tex2D(Texture01SL, pC4 + g2).rgb;
	float3 C7 = tex2D(Texture01SL, pC4 + dy).rgb;
	float3 C8 = tex2D(Texture01SL, pC4 + g1).rgb;
	
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
	float2 inv_size = 1.75 * o * ReShade::PixelSize;	
	float2 size     = 1.0/inv_size;

	float2 dx = float2(inv_size.x,0.0);
	float2 dy = float2(0.0, inv_size.y);
	float2 g1 = float2(inv_size.x,inv_size.y);
	float2 g2 = float2(-inv_size.x,inv_size.y);
	
	float2 pC4 = uv1;	
	
	// Reading the texels
	float3 c00 = tex2D(Texture02SL,pC4 - g1).rgb; 
	float3 c10 = tex2D(Texture02SL,pC4 - dy).rgb;
	float3 c20 = tex2D(Texture02SL,pC4 - g2).rgb;
	float3 c01 = tex2D(Texture02SL,pC4 - dx).rgb;
	float3 c11 = tex2D(Texture02SL,pC4     ).rgb;
	float3 c21 = tex2D(Texture02SL,pC4 + dx).rgb;
	float3 c02 = tex2D(Texture02SL,pC4 + g2).rgb;
	float3 c12 = tex2D(Texture02SL,pC4 + dy).rgb;
	float3 c22 = tex2D(Texture02SL,pC4 + g1).rgb;
	
	float3 d11 = c11;

	float3 mn1 = min (min (c00,c01),c02);
	float3 mn2 = min (min (c10,c11),c12);
	float3 mn3 = min (min (c20,c21),c22);
	float3 mx1 = max (max (c00,c01),c02);
	float3 mx2 = max (max (c10,c11),c12);
	float3 mx3 = max (max (c20,c21),c22);
   
	mn1 = min(min(mn1,mn2),mn3);
	mx1 = max(max(mx1,mx2),mx3);

	float3 contrast = mx1 - mn1;
	float m = max(max(contrast.r,contrast.g),contrast.b);
	
	float DB1 = DBL; float dif;

	float3 dif1 = abs(c11-mn1) + 0.0001; float3 df1 = pow(dif1,float3(DB1,DB1,DB1));
	float3 dif2 = abs(c11-mx1) + 0.0001; float3 df2 = pow(dif2,float3(DB1,DB1,DB1)); 
	
	float3 df = df1/(df1 + df2);
	d11 = lerp(mn1,mx1,df);
	
	c11 = lerp(c11, d11, saturate(2.0*m-0.125));
	
	d11 = lerp(d11,c11,SMART);
	
	return d11;
} 


technique TWO_D_SCALER_LEVEL2
{
	pass twod1
	{
		VertexShader = PostProcessVS;
		PixelShader = TWODS0;
		RenderTarget = Texture01L; 		
	}
	
	pass twod2
	{
		VertexShader = PostProcessVS;
		PixelShader = TWODS1;
		RenderTarget = Texture02L; 		
	}

	pass twod2
	{
		VertexShader = PostProcessVS;
		PixelShader = DEB;
	}	
} 
