#!/usr/bin/env bash

set -u
export LC_ALL=C
ulimit -c 0
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TEMP_DIR="$(mktemp -d)" || exit 2
trap 'rm -rf -- "${TEMP_DIR}"' EXIT
PASSES=0
FAILURES=0

check() {
    local description="$1"
    shift
    if "$@" > /dev/null 2>&1; then
        printf 'PASS: %s\n' "${description}"
        PASSES=$((PASSES + 1))
    else
        printf 'FAIL: %s\n' "${description}"
        FAILURES=$((FAILURES + 1))
    fi
}

is_binary() {
    [[ -f "$1" && -x "$1" ]] || return 1
    [[ "$(file -b -- "$1")" == ELF*executable* ]]
}

matches_tests() {
    local program="$1"
    local input="" expected=""
    local count=0
    is_binary "${program}" || return 1
    for input in "${WORKSPACE}/tests"/test*.in; do
        [[ -f "${input}" ]] || continue
        expected="${input%.in}.expected"
        [[ -f "${expected}" ]] || return 1
        timeout 3 "${program}" < "${input}" > "${TEMP_DIR}/actual.out" 2> "${TEMP_DIR}/actual.err" || return 1
        cmp -s "${expected}" "${TEMP_DIR}/actual.out" || return 1
        [[ ! -s "${TEMP_DIR}/actual.err" ]] || return 1
        count=$((count + 1))
    done
    (( count == TEST_COUNT ))
}

summary() {
    local total=$((PASSES + FAILURES))
    local width="${#total}"
    printf '\n== Resumen ===============================\n\n'
    printf '%-26s %*d\n' 'Comprobaciones exitosas:' "${width}" "${PASSES}"
    printf '%-26s %*d\n\n' 'Comprobaciones pendientes:' "${width}" "${FAILURES}"
    (( FAILURES == 0 ))
}

TEST_COUNT=4
CODE_DIR="${WORKSPACE}/code"

CHECK_ROOT="${TEMP_DIR}/workspace"
mkdir -p "${CHECK_ROOT}"
cp -a "${WORKSPACE}/." "${CHECK_ROOT}/" || exit 2
CASE_DIR=""
TARGET=""
BUILT=0
OBJECTS=()

prepare_case() {
    CASE_DIR="${CHECK_ROOT}/$1"
    TARGET="$2"
    shift 2
    OBJECTS=("$@")
    BUILT=0
}

build_case() {
    [[ -f "${CASE_DIR}/Makefile" ]] || return 1
    (cd "${CASE_DIR}" && timeout 15 make -B all) || return 1
    local object=""
    for object in "${OBJECTS[@]}"; do
        [[ -f "${CASE_DIR}/${object}" ]] || return 1
    done
    is_binary "${CASE_DIR}/${TARGET}" || return 1
    BUILT=1
}

compile_options() {
    (( BUILT == 1 )) || return 1
    local line="" flag="" count=0
    local plan="${TEMP_DIR}/plan.txt"
    (cd "${CASE_DIR}" && timeout 15 make -Bn all) > "${plan}" || return 1
    while IFS= read -r line; do
        # Acepta comillas alrededor de opciones sin exigir una receta literal.
        line="${line//\'/}"
        line="${line//\"/}"
        [[ " ${line} " == *" -c "* ]] || continue
        for flag in -Wall -Wextra -Werror -std=c11 -g -O0; do
            [[ " ${line} " == *" ${flag} "* ]] || return 1
        done
        count=$((count + 1))
    done < "${plan}"
    (( count == ${#OBJECTS[@]} ))
}

dependency_files() {
    (( BUILT == 1 )) || return 1
    local object=""
    for object in "${OBJECTS[@]}"; do
        [[ -s "${CASE_DIR}/${object%.o}.d" ]] || return 1
    done
}

case_matches() {
    (( BUILT == 1 )) || return 1
    matches_tests "${CASE_DIR}/${TARGET}"
}

no_rebuild() {
    (( BUILT == 1 )) || return 1
    local files=("${OBJECTS[@]}" "${TARGET}")
    local before=() name="" index=0
    for name in "${files[@]}"; do
        before+=("$(stat -c %y "${CASE_DIR}/${name}")")
    done
    (cd "${CASE_DIR}" && timeout 15 make) || return 1
    for name in "${files[@]}"; do
        [[ "${before[index]}" == "$(stat -c %y "${CASE_DIR}/${name}")" ]] || return 1
        index=$((index + 1))
    done
}

incremental() {
    (( BUILT == 1 )) || return 1
    local modified="$1"
    local expected=" $2 "
    local before=() object="" index=0 after=""
    local target_before=""
    for object in "${OBJECTS[@]}"; do
        before+=("$(stat -c %y "${CASE_DIR}/${object}")")
    done
    target_before="$(stat -c %y "${CASE_DIR}/${TARGET}")"
    sleep 0.05
    touch "${CASE_DIR}/${modified}" || return 1
    (cd "${CASE_DIR}" && timeout 15 make) || return 1
    for object in "${OBJECTS[@]}"; do
        after="$(stat -c %y "${CASE_DIR}/${object}")"
        if [[ "${expected}" == *" ${object} "* ]]; then
            [[ "${before[index]}" != "${after}" ]] || return 1
        else
            [[ "${before[index]}" == "${after}" ]] || return 1
        fi
        index=$((index + 1))
    done
    [[ "${target_before}" != "$(stat -c %y "${CASE_DIR}/${TARGET}")" ]] || return 1
    case_matches
}

protected_files() {
    find "${CHECK_ROOT}" -type f \
        \( -name '*.c' -o -name '*.h' -o -name Makefile -o -name '*.in' \
        -o -name '*.expected' -o -name '*.sh' \
        -o -name evacuacion_manual \) \
        -exec sha256sum {} + | LC_ALL=C sort
}

clean_target() {
    local clean_tests="$1"
    (( BUILT == 1 )) || return 1
    local object="" generated=""
    protected_files > "${TEMP_DIR}/protected.before"
    if [[ "${clean_tests}" == yes ]]; then
        for generated in out err diff; do
            printf '%s\n' 'Temporal de verificacion' > "${CHECK_ROOT}/tests/test001.${generated}"
        done
    fi
    touch "${CASE_DIR}/clean"
    (cd "${CASE_DIR}" && timeout 15 make clean) || return 1
    [[ ! -e "${CASE_DIR}/${TARGET}" ]] || return 1
    for object in "${OBJECTS[@]}"; do
        [[ ! -e "${CASE_DIR}/${object}" && ! -e "${CASE_DIR}/${object%.o}.d" ]] || return 1
    done
    if [[ "${clean_tests}" == yes ]]; then
        for generated in "${CHECK_ROOT}/tests/"*.out "${CHECK_ROOT}/tests/"*.err "${CHECK_ROOT}/tests/"*.diff; do
            [[ ! -e "${generated}" ]] || return 1
        done
    fi
    protected_files > "${TEMP_DIR}/protected.after"
    cmp -s "${TEMP_DIR}/protected.before" "${TEMP_DIR}/protected.after" || return 1
    rm -f "${CASE_DIR}/clean"
}

check_project() {
    local section="$1"
    check "[${section}] ${TARGET} se construye desde sus archivos objeto" build_case
    check "[${section}] La compilación utiliza los flags solicitados" compile_options
    check "[${section}] Se generan los archivos de dependencias" dependency_files
    check "[${section}] El programa construido supera los cuatro tests" case_matches
}

printf '%s\n' '========================================='
printf '%s\n' '==   Verificación de laboratorio PR4   =='
printf '%s\n' '========================================='
printf '\n== Actividades ==========================\n\n'
check '[1.2] evacuacion_manual corresponde a un binario y supera los cuatro tests' matches_tests "${CODE_DIR}/evacuacion_manual"
check '[2.1] tests-run.sh tiene permiso de ejecución' test -x "${SCRIPT_DIR}/tests-run.sh"

prepare_case code evacuacion main.o parser.o capacity.o priority.o report.o
check_project '2.1'
check '[2.2] Sin cambios no se recompila ni se enlaza' no_rebuild
check '[2.2] capacity.c actualiza solamente capacity.o y el ejecutable' incremental capacity.c 'capacity.o'
check '[2.2] request.h actualiza los cuatro objetos que lo utilizan y el ejecutable' incremental request.h 'main.o parser.o capacity.o report.o'
check '[2.2] clean elimina los archivos generados y conserva fuentes, tests y el ejecutable manual' clean_target yes
check '[3] check.sh tiene permiso de ejecución' test -x "${SCRIPT_DIR}/check.sh"
summary
