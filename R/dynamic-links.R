#' @title Firebase Dynamic Links Service
#' @description Functions for creating Firebase Dynamic Links (short URLs)
#' @name firebase_dynamic_links
#'
#' @section Note:
#' Firebase Dynamic Links is deprecated and will be shut down in August 2025.
#' Consider using alternative URL shortening services for new projects.
NULL

#' Create Dynamic Link
#'
#' Creates a short dynamic link that can route users to specific content
#' in your app or website.
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
#' @return Response containing the short link
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
  # Resolve API key
  if (!is.null(conn) && is_firebase_connection(conn)) {
    api_key <- conn$api_key
  }
  api_key <- firebase_config_get("api_key", value = api_key)

  if (is.null(api_key)) {
    stop_firebase("validation", "API key is required for Dynamic Links")
  }

  # Build URL
  url <- paste0(FIREBASE_DYNAMIC_LINKS_URL, "/shortLinks?key=", api_key)

  # Build dynamic link info
  dynamic_link_info <- list(
    domainUriPrefix = domain_uri_prefix,
    link = link
  )

  # Add social metadata if provided
  if (!is.null(social_title) || !is.null(social_description) || !is.null(social_image_link)) {
    dynamic_link_info$socialMetaTagInfo <- list(
      socialTitle = social_title %||% "",
      socialDescription = social_description %||% "",
      socialImageLink = social_image_link %||% ""
    )
  }

  # Add Android info if provided
  if (!is.null(android_package_name)) {
    dynamic_link_info$androidInfo <- list(
      androidPackageName = android_package_name,
      androidFallbackLink = android_fallback_link
    )
  }

  # Add iOS info if provided
  if (!is.null(ios_bundle_id)) {
    dynamic_link_info$iosInfo <- list(
      iosBundleId = ios_bundle_id,
      iosFallbackLink = ios_fallback_link
    )
  }

  # Build request body
  body <- list(
    dynamicLinkInfo = dynamic_link_info,
    suffix = list(option = if (short) "SHORT" else "UNGUESSABLE")
  )

  # Make request
  firebase_post(url = url, body = body)
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
#' @return Response with short link
#' @export
get_dynamic_link <- function(project_api,
                             domain,
                             link,
                             short = TRUE,
                             social_title = "",
                             social_description = "",
                             social_image_link = "") {
  .Deprecated("dynlink_create")

  option <- ifelse(short, "SHORT", "UNGUESSABLE")

  url <- paste0(
    "https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=",
    project_api
  )

  response <- httr::POST(
    url = url,
    body = list(
      dynamicLinkInfo = list(
        dynamicLinkDomain = domain,  # Note: Legacy parameter name
        link = link,
        socialMetaTagInfo = list(
          socialTitle = social_title,
          socialDescription = social_description,
          socialImageLink = social_image_link
        )
      ),
      suffix = list(option = option)
    ),
    encode = "json"
  )

  httr::content(response)
}
