#' @name box/api
#' @title Plumber API Module
#' @description REST API endpoints for micromort/microlife datasets.

box::use(
  ./endpoints[create_api, launch_api]
)

#' @export
box::export(
  create_api,
  launch_api
)
