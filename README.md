# FPGA/Verilog RTL 설계 교과서

Xilinx FPGA 환경을 기준으로, Verilog RTL이 실제 하드웨어 자원으로 어떻게 합성되고 배치되는지를 구조적으로 설명하는 설계 교재입니다.  
단순 문법 설명이 아니라, **RTL 코드가 LUT, FF, carry chain, DSP, BRAM, LUTRAM, SRL 등으로 어떻게 대응되는지**, 그리고 그 선택이 **area, timing, fanout, routing, verification**에 어떤 영향을 주는지를 설계 관점에서 정리했습니다.

## 목적

이 문서는 다음과 같은 질문에 답할 수 있도록 구성했습니다.

- 어떤 Verilog 코드가 어떤 FPGA 자원으로 내려가는가
- 같은 기능이라도 왜 어떤 코드는 더 무겁고, 어떤 코드는 더 빠른가
- area와 timing을 함께 보려면 RTL을 어떤 기준으로 작성해야 하는가
- 단순히 동작하는 코드가 아니라, 합성과 구현 결과까지 고려한 RTL은 어떻게 달라지는가

## 구성 방식

이 교재는 문법 중심 설명보다는 **구조와 판단 기준** 중심으로 전개됩니다.

- FPGA 자원 관점에서 RTL 해석
- 좋은 코드와 주의할 코드를 비교
- area, timing, routing, fanout 관점에서 trade-off 설명
- inference와 mapping이 어떻게 달라지는지 설명
- verification 시 주의할 점까지 함께 정리

즉, “이 문법은 이렇게 쓴다”보다는  
“이렇게 쓰면 왜 이런 하드웨어가 만들어지고, 언제 불리해지는가”를 기준으로 설명합니다.

## 다루는 내용

- LUT, FF, slice의 기본 구조
- carry chain과 adder/subtractor 구조
- comparator, mux, reduction logic
- shift register와 SRL inference
- BRAM, LUTRAM, distributed memory inference
- DSP48 활용과 산술 연산 mapping
- fanout, packing, placement, routing의 영향
- area와 timing을 함께 보는 RTL 설계 기준
- verification 관점에서 자주 놓치는 부분

## 읽는 흐름

문서는 대체로 다음 흐름으로 읽히도록 구성했습니다.

1. **FPGA 기본 자원 이해**  
   RTL이 최종적으로 어떤 물리 자원으로 구현되는지 먼저 설명합니다.

2. **RTL과 합성 결과의 연결**  
   특정 코드 패턴이 어떤 구조로 합성되는지 설명합니다.

3. **설계 패턴 비교**  
   같은 기능을 수행하는 여러 RTL 스타일을 비교하고, 각각의 장단점을 분석합니다.

4. **area/timing trade-off 해석**  
   단순히 resource 수치만 보는 것이 아니라, timing과 routing까지 포함해 해석합니다.

5. **실전 설계 판단 기준 정리**  
   실제 RTL 작성 시 어떤 선택을 해야 하는지 체크리스트 형태로 정리합니다.

## 이런 분들에게 적합합니다

- FPGA에서 Verilog RTL 설계를 시작했지만, 합성 결과 해석이 어려운 분
- 코드는 작성할 수 있지만 area/timing 최적화 기준이 정리되지 않은 분
- Xilinx FPGA에서 inference와 자원 mapping을 구조적으로 이해하고 싶은 분
- 단순 예제가 아니라 실전 RTL 관점의 설명이 필요한 분

## 특징

- Xilinx FPGA 기준 설명
- 구조 중심, 설계 판단 중심 서술
- area와 timing을 함께 보는 관점 강조
- 좋은 코드 / 주의할 코드 / 더 나은 코드의 비교 포함
- verification까지 고려한 설명

## 문서 활용 방법

처음부터 순서대로 읽어도 되고,  
필요한 주제만 골라서 참고서처럼 사용해도 됩니다.

특히 아래와 같은 상황에서 바로 참고할 수 있습니다.

- adder나 comparator가 너무 커졌을 때
- BRAM inference가 기대대로 되지 않을 때
- fanout이나 routing 때문에 timing이 깨질 때
- shift register가 FF로만 구현될 때
- 같은 기능인데 area 차이가 크게 나는 이유를 확인하고 싶을 때

## 키워드

`FPGA` `Verilog` `RTL` `Xilinx` `LUT` `FF` `DSP48` `BRAM` `LUTRAM` `SRL` `timing` `area` `inference` `placement` `routing` `verification`

## 참고

이 문서는 FPGA RTL 설계를 “문법”보다 “구조”로 이해하기 위한 교재를 목표로 합니다.  
따라서 각 장에서는 코드 자체보다도, **그 코드가 어떤 하드웨어를 만들고 어떤 비용을 유발하는지**를 우선해서 설명합니다.
