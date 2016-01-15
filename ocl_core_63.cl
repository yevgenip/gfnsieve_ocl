MSTRINGIFY(

#define u32 uint\n
#define u64 ulong\n

__kernel void process63(__constant u64 *fac_mult_ratio, __constant u64 *init, __global u32 *RES)
{
	u32 index         = get_global_id(0);
	u32 si            = index >> init_fac_shift;
	u32 shift_index_3 = si * 3;

	u64 f; /* factor to be checked */
	u64 i; /* initial value */
	u64 m; /* multiplier - should be a power of i */
	u64 r; /* inverse of multiplier */
	/* (param) u32 bmax; */ /* range of admissible candidate. only hits < bmax need to be considered. bmax should be odd. */
	u32 count; /* how many iterations thru the main loop. inversely proportional to the power of i used in multiplier */
	/* (param) u32 *RES; */ /* global array to which successes, if any, should be returned */

	f = fac_mult_ratio[shift_index_3];
	i = init[index];
	m = fac_mult_ratio[shift_index_3+1];
	r = fac_mult_ratio[shift_index_3+2];
	count = param_count;

	do { /* loop down */

		/* only bothered about even valued candidates. choose either i or f-i */
		//u64 tmp = (i & 1) - 1; /* tmp = FF..FF or 00..00 */
		//i = (i & tmp) | ((f - i) & ~tmp);
		if(i & 1)
			i = f-i;

		/* check if we have an even-valued success */
		if(i < bmax) {
			u32 count = atomic_inc(&RES[0]) + 1;
			RES[count*2-1] = (u32) i; /* TODO: Add array bounds check */
			RES[count*2] = si;
		}

		/* compute next iteration of i in 4 steps */
		u64 q = mul_hi(i, r) + 1;	// step 1 - compute quotient
		u64 p = i*m;					// step 2 - compute actual product i * m
		u64 g = q*f;					// step 3 - compute approximate quantity to subtract

		// step 4: compute the difference (p - g) with branchless code for correcting negatives
		i = (p-g);
		if (i & 0x8000000000000000)
			i += f;
	} while( --count ); // End of countdown loop
}

);

#if 0

__device__ static void process63
(
	u64 f, /* factor to be checked */
	u64 i, /* initial value */
	u64 m, /* multiplier - should be a power of i */
	u64 r, /* inverse of multiplier */
	u32 bmax, /* range of admissible candidate. only hits < bmax need to be considered. bmax should be odd. */
	u32 count, /* how many iterations thru the main loop. inversely proportional to the power of i used in multiplier */
	u32 *RES, /* global array to which successes, if any, should be returned */
	u32 si
)
{
	do { /* loop down */

		/* only bothered about even valued candidates. choose either i or f-i */
		//u64 tmp = (i & 1) - 1; /* tmp = FF..FF or 00..00 */
		//i = (i & tmp) | ((f - i) & ~tmp);
		if(i & 1)
			i = f-i;

		/* check if we have an even-valued success */
		if(i < bmax) {
			u32 count = atomicInc(&RES[0], RESULT_BUFFER_COUNT) + 1;
			RES[count*2-1] = (u32) i; /* TODO: Add array bounds check */
			RES[count*2] = si;
		}

		/* compute next iteration of i in 4 steps */
		u64 q = __umul64hi(i, r) + 1;	// step 1 - compute quotient
		u64 p = i*m;					// step 2 - compute actual product i * m
		u64 g = q*f;					// step 3 - compute approximate quantity to subtract

		// step 4: compute the difference (p - g) with branchless code for correcting negatives
		i = (p-g);
		if (i & 0x8000000000000000)
			i += f;
	} while( --count ); // End of countdown loop
}

__global__ void gfn_kernel63(u64 *fac_mult_ratio, u64 *init, u32 bmax, u32 count, u32 *RES, u32 init_fac_shift)
{
	int index = blockDim.x * blockIdx.x + threadIdx.x;
	int shift_index = index >> init_fac_shift;

	process63(fac_mult_ratio[shift_index*3], init[index], fac_mult_ratio[shift_index*3+1], fac_mult_ratio[shift_index*3+2], bmax, count, RES, shift_index);
}

#endif
