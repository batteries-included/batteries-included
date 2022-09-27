@test "Test Health" {
  url="http://battery-grafana/api/health"
  ulimit -a
  result=$(wget --server-response --spider --timeout 90 --tries 10 --wait 60 --retry-connrefused --retry-on-host-error ${url})
  code=$(echo "${result}" | awk '/^  HTTP/{print $2}')
  [ "$code" == "200" ]
}