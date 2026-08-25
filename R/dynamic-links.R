#' @title Firebase Dynamic Links Service
#' @description Functions for creating Firebase Dynamic Links (short URLs)
#' @name firebase_dynamic_links
#'
#' @section Note:
#' Firebase Dynamic Links shut down on August 25, 2025. These functions are
#' retained for compatibility, but the upstream service no longer creates or
#' serves links. Use another deep-linking provider for new projects.
NULL

#' Create Dynamic Link
#'
#' Legacy interface for the discontinued Firebase Dynamic Links service.
#' Requests to the upstream service no longer succeed.
#'
#' @param conn Firebase connection object (or NULL to use config)
#' @param link The URL you want to shorten/wrap
#' @param domain_uri_prefix Your Firebase Dynamic Links domain (e.g., "https://example.page.link")
#' @param short Whether to create a short link (TRUE) or unguessable link (FALSE)
#' @param social_title Title for social media previews
#' @param social_description Description for social media previews
#' @param social_image_link Image URL for social media previews
#' @param android_package_name Android app package name
#' @param android_fallback_link Fallback URL for Android
#' @param ios_bundle_id iOS app bundle ID
#' @param ios_fallback_link Fallback URL for iOS
#' @param api_key Firebase API key (used if conn is NULL)
#' @return This function always raises an error because the upstream service has
#'   been shut down.
#' @export
#' @examples
#' \dontrun{
#' conn <- firebase_connect(project_id = "my-project", api_key = "...")
#'
#' result <- dynlink_create(
#'   conn,
#'   link = "https://example.com/page",
#'   domain_uri_prefix = "https://example.page.link",
#'   social_title = "Check this out!",
#'   social_description = "An amazing page"
#' )
#'
#' print(result$shortLink)
#' }
dynlink_create <- function(conn = NULL,
                           link,
                           domain_uri_prefix,
                           short = TRUE,
                           social_title = NULL,
                           social_description = NULL,
                           social_image_link = NULL,
                           android_package_name = NULL,
                           android_fallback_link = NULL,
                           ios_bundle_id = NULL,
                           ios_fallback_link = NULL,
                           api_key = NULL) {
  stop_firebase(
    "validation",
    paste(
      "Firebase Dynamic Links shut down on August 25, 2025;",
      "new short links can no longer be created."
    )
  )

}

# ============================================================================
# Deprecated Legacy Function
# ============================================================================

#' @title Create Dynamic Link (Legacy)
#' @description Legacy function. Use dynlink_create() instead.
#' @param project_api Firebase API key
#' @param domain Dynamic Links domain
#' @param link URL to shorten
#' @param short Whether to create short link
#' @param social_title Social preview title
#' @param social_description Social preview description
#' @param social_image_link Social preview image
#' @return This function always raises an error because the upstream service has
#'   been shut down.
#' @export
get_dynamic_link <- function(project_api,
                             domain,
                             link,
                             short = TRUE,
                             social_title = "",
                             social_description = "",
                             social_image_link = "") {
  .Deprecated("dynlink_create")
  dynlink_create(
    link = link,
    domain_uri_prefix = domain,
    short = short,
    social_title = social_title,
    social_description = social_description,
    social_image_link = social_image_link,
    api_key = project_api
  )
}
