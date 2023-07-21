#include <torch/extension.h>

typedef torch::PackedTensorAccessor32<int32_t, 2, torch::RestrictPtrTraits> int_2d;
typedef torch::PackedTensorAccessor32<float, 2, torch::RestrictPtrTraits> float_2d;
typedef torch::PackedTensorAccessor32<float, 3, torch::RestrictPtrTraits> float_3d;


__global__ void weighted_sum_kernel(
    const float_3d x,
    const int_2d group,
    const float_2d weights,
    float_3d y
) {
    int B = x.size(0);
    int N = x.size(1);
    int D = x.size(2);
    int C = y.size(1);

    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int b_idx = idx / N;
    int n_idx = idx % N;
    if (b_idx >= B) return;

    int c_idx = group[b_idx][n_idx];
    if (c_idx < 0 || c_idx >= C) return;

    float w = weights[b_idx][c_idx];
    for (int d_idx = 0; d_idx < D; d_idx++) {
        atomicAdd(&y[b_idx][c_idx][d_idx], x[b_idx][n_idx][d_idx] * w);
    }
}

void weighted_sum(
    const torch::Tensor x,
    const torch::Tensor group,
    const torch::Tensor weights,
    torch::Tensor y
) {
    int B = x.size(0);
    int N = x.size(1);
    int D = x.size(2);
    int C = y.size(1);

    const int threads = 1024;
    int blocks = (B*N - 1) / threads + 1;

    weighted_sum_kernel<<<blocks, threads>>>(
        x.packed_accessor32<float, 3, torch::RestrictPtrTraits>(),
        group.packed_accessor32<int32_t, 2, torch::RestrictPtrTraits>(),
        weights.packed_accessor32<float, 2, torch::RestrictPtrTraits>(),
        y.packed_accessor32<float, 3, torch::RestrictPtrTraits>()
    );
}

PYBIND11_MODULE(TORCH_EXTENSION_NAME, m) {
    m.def("_weighted_sum", &weighted_sum);
}
