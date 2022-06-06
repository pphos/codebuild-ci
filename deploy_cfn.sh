#!/bin/bash
set -euo pipefail

#####################################
# 定数
#####################################
readonly CAPABILITIES="CAPABILITY_NAMED_IAM"

#####################################
# 設定ファイルの読み取り
# Arguments
#   $1  : 設定ファイルのパス
#####################################
function load_config() {
  local config_path=$1

  if [ -f "${config_path}" ]; then
    config_json=$(cat "${config_path}")
    echo "${config_json}"
  else
    echo "Error: ${config_json} dose not exist."
    exit 1
  fi
}

#####################################
# 引数の数が1つか2つだけかの確認
# Arguments:
#   $0 : 実行スクリプトのファイル名
#   $1 : 引数の個数
#####################################
function isArgumentOneOrTwo() {
  local file_name=$0
  local arguments_count=$1

  if [ "${arguments_count}" -eq 1 ] || [ "${arguments_count}" -eq 2 ]; then
    return 0
  else
    echo "Usage: ${file_name} <CONFIG_PATH>"
    echo "Usage: ${file_name} <CONFIG_PATH> deploy"
    echo "If you specify 'deploy' option, AWS CLI execute changesets automatically."
    exit 1
  fi
}

#####################################
# 上書きパラメータの取得
# Arguments:
#   $1 : 設定パラメータのjson
#####################################
function extract_override_parameters() {
  local parameters="$(echo ${1} | jq -r '.parameters')"
  local parameter_overrides=""
  local parameters_len=$(echo "${parameters}" | jq length)

  # 上書きパラメータの取得
  for j in $( seq 0 $((parameters_len - 1)) ); do
    parameter=$(echo "${parameters}" | jq .["${j}"])
    key=$(echo "${parameter}" | jq -r '.key')
    value=$(echo "${parameter}" | jq -r '.value')

    parameter_overrides="${parameter_overrides} ${key}=${value}"
  done

  echo "${parameter_overrides}"
}
#####################################
# AWS CLI実行コマンドの整形
# Globals
#   CAPABILITIES: 'CAPABILITY_IAM', 'CAPABILITY_NAMED_IAM'のいづれかを指定
# Arguments:
#   $1          : スタック名
#   $2          : テンプレートファイルのパス
#   $3          : 上書き対象のパラメータ (key1=value1 key2=value2)の形式
#   $4          : スクリプト実行時の引数の数
#####################################
function format_aws_cli_cmd() {
  local stack_name="--stack-name ${1}"
  local template_file="--template-file ${2}"
  local capabilities="--capabilities ${CAPABILITIES}"
  local parameter_overrides="${3}"
  local changeset_option="--no-execute-changeset"
  local script_args="${4}"

  if [ -n "${parameter_overrides}" ]; then
    parameter_overrides="--parameter-overrides ${parameter_overrides}"
  fi

  if [ "${script_args}" -eq 2 ]; then
    changeset_option=""
  fi

  # AWS CLI実行コマンドの整形
  CMD="aws cloudformation deploy ${stack_name} ${template_file} ${capabilities} ${parameter_overrides} ${changeset_option}"
  echo "${CMD}"
}


#####################################
# メインの処理
#####################################
# 引数が1つか2つだけかの確認
isArgumentOneOrTwo $#
if [ $# -eq 2 ] && [ $2 != 'deploy' ]; then
  echo "Usage: ${0} <CONFIG_PATH> deploy"
  echo "Second arguments must be 'deploy', other string dose not allowed."
  exit 1
fi

# Cloudformationのパラメータ設定ファイル
config_json="${1}"

# 設定ファイルの読み取り
config=$(load_config "${config_json}")
# 配列の最後のインデックスを取得
config_len=$(echo "${config}" | jq length)

for i in $( seq 0 $((config_len - 1)) ); do
  stack=$(echo "${config}" | jq .["${i}"])
  stack_name=$(echo "${stack}" | jq -r '.stack_name')
  template_file=$(echo "${stack}" | jq -r '.template_file')

  # 上書きするパラメータの設定
  parameter_overrides=$(extract_override_parameters "${stack}")
  # AWS CLI実行コマンドの整形
  CMD=$(format_aws_cli_cmd "${stack_name}" "${template_file}" "${parameter_overrides}" $#)
  # CloudFormationのデプロイ
  echo "${CMD}"
  ${CMD}
done