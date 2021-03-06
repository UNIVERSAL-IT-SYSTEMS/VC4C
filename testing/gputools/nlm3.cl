
#ifndef FS
#define FS 2
#endif

#ifndef BS
#define BS 3
#endif /* BS */

#define NPATCH ((2.f*FS+1)*(2.f*FS+1)*(2.f*FS+1))


__kernel void dist(__read_only image3d_t input,__write_only image3d_t output, const int dx,const int dy,const int dz){


const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE |	CLK_ADDRESS_CLAMP_TO_EDGE |	CLK_FILTER_NEAREST ;

uint i0 = get_global_id(0);
uint j0 = get_global_id(1);
uint k0 = get_global_id(2);

float pix1  = read_imagef(input,sampler,(int4)(i0,j0,k0,0)).x;
float pix2  = read_imagef(input,sampler,(int4)(i0+dx,j0+dy,k0+dz,0)).x;

float d = (pix1-pix2);


d = d*d/NPATCH;


write_imagef(output,(int4)(i0,j0,k0,0),(float4)(d,0,0,0));
  

}


__kernel void convolve(__read_only image3d_t input, __write_only image3d_t output, const int flag){

  // flag = 1 -> in x axis 
  // flag = 2 -> in y axis 
  // flag = 4 -> in z axis 
  
  const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE |	CLK_ADDRESS_CLAMP_TO_EDGE |	CLK_FILTER_NEAREST ;

  uint i0 = get_global_id(0);
  uint j0 = get_global_id(1);
  uint k0 = get_global_id(2);

  const int dx = flag & 1;
  const int dy = (flag&2)/2;
  const int dz = (flag&4)/4;

  float res = 0;

  for (int i = -FS; i <= FS; ++i)
    res += read_imagef(input,sampler,(int4)(i0+dx*i,j0+dy*i,k0+dz*i,0)).x;

  write_imagef(output,(int4)(i0,j0,k0,0),(float4)(res,0,0,0));
  
}

	

__kernel void computePlus(__read_only image3d_t input,__read_only image3d_t distImg,
						  __global float* accBuf,__global float* weightBuf,
						  const int Nx,const int Ny,const int Nz,  const int dx,const int dy,const int dz, const float sigma){

  
  const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE |	CLK_ADDRESS_CLAMP_TO_EDGE |	CLK_FILTER_NEAREST ;

  uint i0 = get_global_id(0);
  uint j0 = get_global_id(1);
  uint k0 = get_global_id(2);

  float dist  = read_imagef(distImg,sampler,(int4)(i0,j0,k0,0)).x;

  float pix  = read_imagef(input,sampler,(int4)(i0+dx,j0+dy,k0+dz,0)).x;

  float weight = exp(-1.f*dist/sigma/sigma);

  accBuf[i0+Nx*j0+Nx*Ny*k0] += (float)(weight*pix);
  weightBuf[i0+Nx*j0+Nx*Ny*k0] += (float)(weight);


}


__kernel void computeMinus(__read_only image3d_t input,__read_only image3d_t distImg,
						   __global float* accBuf,__global float* weightBuf,
						   const int Nx,const int Ny,const int Nz, const int dx,const int dy,const int dz, const float sigma){

  
  const sampler_t sampler = CLK_NORMALIZED_COORDS_FALSE |	CLK_ADDRESS_CLAMP_TO_EDGE |	CLK_FILTER_NEAREST ;

  uint i0 = get_global_id(0);
  uint j0 = get_global_id(1);
  uint k0 = get_global_id(2);

  float dist  = read_imagef(distImg,sampler,(int4)(i0-dx,j0-dy,k0-dz,0)).x;

  float pix  = read_imagef(input,sampler,(int4)(i0-dx,j0-dy,k0-dz,0)).x;



  float weight = exp(-1.f*dist/sigma);

  accBuf[i0+Nx*j0+Nx*Ny*k0] += (float)(weight*pix);
  weightBuf[i0+Nx*j0+Nx*Ny*k0] += (float)(weight);


}

