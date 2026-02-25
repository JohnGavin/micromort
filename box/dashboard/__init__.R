#' @name box/dashboard
#' @title Shinylive Dashboard Module
#' @description Interactive dashboard components for risk visualization.

box::use(
  ./ui[dashboard_ui],
  ./server[dashboard_server]
)

#' @export
box::export(
  dashboard_ui,
  dashboard_server
)
