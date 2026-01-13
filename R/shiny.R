#' @title Shiny Integration for fireData
#' @description Functions to integrate Firebase authentication with Shiny apps
#' @name firebase_shiny
NULL

#' Create Shiny Authentication Server
#'
#' Creates a login overlay for Shiny applications with support for
#' email/password, Google OAuth, and anonymous authentication.
#'
#' @param user A reactiveValues object with a `Logged` field (e.g., `reactiveValues(Logged = FALSE)`)
#' @param input Shiny input object
#' @param output Shiny output object
#' @param credentials Enable email/password login (default: TRUE)
#' @param goauth Enable Google OAuth login (default: TRUE)
#' @param anonymous Enable anonymous login (default: TRUE)
#' @param project_api Firebase API key
#' @param web_client_id Google OAuth client ID (required if goauth = TRUE)
#' @param web_client_secret Google OAuth client secret (required if goauth = TRUE)
#' @param request_uri OAuth redirect URI
#' @return A Shiny UI element containing the login form
#' @export
#' @examples
#' \dontrun{
#' library(shiny)
#' library(fireData)
#'
#' ui <- fluidPage(
#'   useShinyjs(),
#'   uiOutput("app")
#' )
#'
#' server <- function(input, output, session) {
#'   USER <- reactiveValues(Logged = FALSE)
#'
#'   output$app <- renderUI({
#'     if (!USER$Logged) {
#'       shiny_auth_server(
#'         user = USER,
#'         input = input,
#'         output = output,
#'         project_api = "your-api-key",
#'         web_client_id = "your-client-id",
#'         web_client_secret = "your-client-secret",
#'         request_uri = "http://localhost"
#'       )
#'     } else {
#'       # Your main app UI
#'       tagList(
#'         h1("Welcome!"),
#'         actionButton("logout", "Logout")
#'       )
#'     }
#'   })
#' }
#'
#' shinyApp(ui, server)
#' }
shiny_auth_server <- function(user,
                              input,
                              output,
                              credentials = TRUE,
                              goauth = TRUE,
                              anonymous = TRUE,
                              project_api = NULL,
                              web_client_id = NULL,
                              web_client_secret = NULL,
                              request_uri = NULL) {
  # Check for shinyjs
  if (!requireNamespace("shinyjs", quietly = TRUE)) {
    stop_firebase("validation",
      "Package 'shinyjs' is required for Shiny authentication. ",
      "Install with: install.packages('shinyjs')"
    )
  }

  # Resolve API key from config if not provided
  project_api <- project_api %||% firebase_config_get("api_key")

  if (is.null(project_api)) {
    stop_firebase("validation", "Firebase API key (project_api) is required")
  }

  # Anonymous login handler
  if (anonymous) {
    shiny::observeEvent(input$.anonymous, {
      token <- tryCatch(
        auth_anonymous(api_key = project_api),
        error = function(e) list(error = conditionMessage(e))
      )

      if (!is.null(token$idToken)) {
        user$Logged <- TRUE
        user$Token <- token
      } else {
        shinyjs::show("message")
        output$message <- shiny::renderText("Anonymous login failed. Please try again.")
        shinyjs::delay(2000, shinyjs::hide("message", anim = TRUE, animType = "fade"))
      }
    })

    shiny::insertUI(
      selector = "#login",
      where = "afterBegin",
      ui = shiny::div(
        shiny::actionButton(".anonymous", "Anonymous login"),
        style = "text-align: center; margin-bottom: 10px;"
      )
    )
  }

  # Google OAuth handler
  if (goauth) {
    if (is.null(web_client_id) || is.null(web_client_secret)) {
      warning("Google OAuth enabled but client credentials not provided")
    }

    shiny::observeEvent(input$.goauth, {
      token <- tryCatch(
        auth_google(
          api_key = project_api,
          client_id = web_client_id,
          client_secret = web_client_secret,
          request_uri = request_uri %||% "http://localhost"
        ),
        error = function(e) list(error = conditionMessage(e))
      )

      if (!is.null(token$oauthIdToken) || !is.null(token$idToken)) {
        user$Logged <- TRUE
        user$Token <- token
      } else {
        shinyjs::show("message")
        output$message <- shiny::renderText("Google login failed. Please try again.")
        shinyjs::delay(1500, shinyjs::hide("message", anim = TRUE, animType = "fade"))
      }
    })

    shiny::insertUI(
      selector = "#login",
      where = "afterBegin",
      ui = shiny::div(
        shiny::actionButton(".goauth", "Google login"),
        style = "text-align: center; margin-bottom: 10px;"
      )
    )
  }

  # Email/password login handler
  if (credentials) {
    shiny::observeEvent(input$.login, {
      token <- tryCatch(
        auth_sign_in(
          api_key = project_api,
          email = input$.username,
          password = input$.password
        ),
        error = function(e) list(error = conditionMessage(e))
      )

      if (!is.null(token$idToken)) {
        user$Logged <- TRUE
        user$Token <- token
      } else {
        shinyjs::show("message")
        output$message <- shiny::renderText("Invalid email or password")
        shinyjs::delay(2000, shinyjs::hide("message", anim = TRUE, animType = "fade"))
      }
    })

    shiny::insertUI(
      selector = "#login",
      where = "afterBegin",
      ui = shiny::tagList(
        shiny::textInput(".username", "Email:"),
        shiny::passwordInput(".password", "Password:"),
        shiny::div(
          shiny::actionButton(".login", "Login"),
          style = "text-align: center;"
        )
      )
    )
  }

  # Return the login panel UI
  shiny::fluidRow(
    shiny::column(
      width = 4,
      offset = 4,
      shiny::wellPanel(
        id = "login",
        style = "margin-top: 50px;"
      ),
      shiny::div(
        id = "message",
        style = "display: none; color: red; text-align: center;",
        shiny::textOutput("message")
      )
    )
  )
}

#' Shiny Authentication UI Helper
#'
#' Creates a styled login panel for Shiny apps.
#' Use with shiny_auth_server() for complete authentication.
#'
#' @param title Title shown on the login panel
#' @return A Shiny UI element
#' @export
#' @examples
#' \dontrun{
#' ui <- fluidPage(
#'   useShinyjs(),
#'   shiny_auth_ui("Sign In")
#' )
#' }
shiny_auth_ui <- function(title = "Sign In") {
  shiny::fluidRow(
    shiny::column(
      width = 4,
      offset = 4,
      shiny::wellPanel(
        shiny::h3(title, style = "text-align: center;"),
        shiny::hr(),
        id = "login"
      ),
      shiny::div(
        id = "message",
        style = "display: none; color: #d9534f; text-align: center; margin-top: 10px;"
      )
    )
  )
}

#' Check Authentication Status
#'
#' Helper to check if user is authenticated in Shiny context.
#'
#' @param user The reactiveValues object used with shiny_auth_server
#' @return TRUE if user is logged in, FALSE otherwise
#' @export
is_authenticated <- function(user) {
  !is.null(user$Logged) && isTRUE(user$Logged)
}

#' Get User Token
#'
#' Gets the Firebase token from authenticated user in Shiny context.
#'
#' @param user The reactiveValues object used with shiny_auth_server
#' @return The ID token string or NULL if not authenticated
#' @export
get_user_token <- function(user) {
  if (is_authenticated(user) && !is.null(user$Token)) {
    user$Token$idToken %||% user$Token$oauthIdToken
  } else {
    NULL
  }
}
