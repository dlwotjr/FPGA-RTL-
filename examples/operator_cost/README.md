# RTL operator resource micro-benchmark

이 예제는 연산자 하나의 절대 비용표를 만들기 위한 것이 아니라, 동일한 boundary
register 조건에서 Verilog 표현이 Xilinx 7-series primitive로 어떻게 합성되는지
확인하기 위한 작은 OOC 실험입니다. 모든 연산자는 `operator_cost_all` 하나에
인스턴스화되며 하나의 in-memory Vivado project에서 synthesis도 한 번만
실행됩니다.

조건:

- Vivado 2020.2
- `xc7z020clg484-1`
- out-of-context synthesis
- input과 output 사이에 register 한 경계
- `flatten_hierarchy none`

실행:

```sh
vivado -mode batch -source run_synth.tcl
```

결과는 `results/summary.tsv`와 단일 hierarchy utilization report로 생성됩니다.
project directory와 checkpoint는 만들지 않습니다. FF 수에는
실험 조건을 고정하기 위한 input/output boundary register가 포함됩니다. LUT와
CARRY4 수 역시 이 작은 top에서의 결과이며, 실제 design hierarchy에서는 constant
propagation, LUT combining, register packing과 fanout 때문에 달라질 수 있습니다.
