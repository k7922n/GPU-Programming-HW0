#include <cstdio>
#include <cstdlib>
#include "SyncedMemory.h"

#define CHECK {\
	auto e = cudaDeviceSynchronize();\
	if (e != cudaSuccess) {\
		printf("At " __FILE__ ":%d, %s\n", __LINE__, cudaGetErrorString(e));\
		abort();\
	}\
}

__global__ void SomeTransform(char *input_gpu, int fsize) {
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx < fsize && input_gpu[idx] != '\n') {
		input_gpu[idx] = '!';
	}
}

__global__ void MyTransform(char *input_gpu, int fsize) {
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx < fsize && input_gpu[idx] != '\n') {
		if(int(input_gpu[idx]) > 64 && input_gpu[idx] < 91)
			{input_gpu[idx] = char(int(input_gpu[idx]) + 32);}
		else if(int(input_gpu[idx]) > 96 && input_gpu[idx] < 123)
			{input_gpu[idx] = char(int(input_gpu[idx]) - 32);}
	}
}

int main(int argc, char **argv)
{
	// init, and check
	if (argc != 2) {
		printf("Usage %s <input text file>\n", argv[0]);
		abort();
	}
	FILE *fp = fopen(argv[1], "r");
	if (! fp) {
		printf("Cannot open %s", argv[1]);
		abort();
	}
	// get file size
	fseek(fp, 0, SEEK_END);
	size_t fsize = ftell(fp);
	fseek(fp, 0, SEEK_SET);

	// read files
	MemoryBuffer<char> text(fsize+1);
	auto text_smem = text.CreateSync(fsize);
	CHECK;
	fread(text_smem.get_cpu_wo(), 1, fsize, fp);
	text_smem.get_cpu_wo()[fsize] = '\0';
	fclose(fp);

	// TODO: do your transform here
	char *input_gpu = text_smem.get_gpu_rw();
	// An example: transform the first 64 characters to '!'
	// Don't transform over the tail
	// And don't transform the line breaks
	//SomeTransform<<<100, 64>>>(input_gpu, fsize);
	
	//MyTransform turns the lower case into upper case and turns the upper case into lower one
	MyTransform<<<100, 64>>>(input_gpu, fsize);
	puts(text_smem.get_cpu_ro());
	return 0;
}
