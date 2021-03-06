#' Modify the model parameters of the thread that runs the simulation run_i
#'
#' @param parameter List providing the parameter table and the parameter
#'   constraints
#' @param thread_parameter The swat_parameter set that will be modified
#'   according to the parpameter set used in the respective thread
#' @param file_meta Table with the meta informations on the SWAT model parameter
#'   files
#' @param run_index Vector of the indices of runs that are performed
#' @param i_run Index that gives the number of the current run simulated in the
#'   respective thread
#'
#' @keywords internal
#'
modify_parameter <- function(parameter, thread_parameter, file_meta, run_index,
                             i_run) {
  for (i_par in 1:ncol(parameter$values)) {
    file_i <- parameter$definition[i_par, ]$file_name

    if(file_i == "mgt") {
      swat_par_i <- parameter$definition$parameter[i_par]
      gen_mgt_par <- c("IGRO", "PHU_PLT", "BIOMIX", "CN2", "USLE_P", "BIO_MIN",
                       "FILTERW", "IURBAN", "URBLU", "IRRSC", "IRRNO", "FLOWMIN",
                       "DIVMAX", "FLOWFR", "DDRAIN", "TDRAIN", "GDRAIN")
      if(swat_par_i %in% gen_mgt_par){
        thread_parameter <-
          modify_gen_par(parameter, thread_parameter, file_meta, i_par, run_index, i_run)
      } else {
        thread_parameter <-
          modify_mgt_par(parameter, thread_parameter, file_meta, i_par, run_index, i_run)
      }
    } else {
      thread_parameter <-
        modify_gen_par(parameter, thread_parameter, file_meta, i_par, run_index, i_run)
    }
  }
  return(thread_parameter)
}

#' General function to modify parameters that are provided in linear table
#' format
#'
#' @param parameter List providing the parameter table and the parameter
#'   constraints
#' @param model_parameter The swat_parameter set that will be modified according
#'   to the parpameter i_par
#' @param file_meta Table with the meta informations on the swat model parameter
#'   files
#' @param i_par Index that gives the number of the curent parameter that is
#'   modified in this step
#' @param run_index Vector of the indices of runs that are performed
#' @param i_run Index that gives the number of the current run simulated in the
#'   respective thread
#'
#' @importFrom dplyr %>% filter
#'
#' @keywords internal
#'
modify_gen_par <- function(parameter, model_parameter, file_meta,
                            i_par, run_index, i_run) {
  par_i <- parameter$definition[i_par, ]
  par_up_i <- parameter$values[[par_i$par_name]][run_index[i_run]]
  file_code_i <- par_i$file_expression %>%
    evaluate_expression(file_meta, .) %>%
    .[["file_code"]]

  idx_i <- model_parameter[[par_i$file_name]][["value"]] %>%
    filter(file_code %in% file_code_i) %>%
    filter_spec_expr(., par_i$spec_expression) %>%
    .[["idx"]]

  model_parameter[[par_i$file_name]][["value"]][[par_i$parameter]] <-
    model_parameter[[par_i$file_name]][["value"]][[par_i$parameter]] %>%
    update_par(., par_up_i, par_i$change, idx_i)

  return(model_parameter)
}

#' Modify parameters that are provided in the management table format
#'
#' @param parameter List providing the parameter table and the parameter
#'   constraints
#' @param model_parameter The swat_parameter set that will be modified according
#'   to the parpameter i_par
#' @param file_meta Table with the meta informations on the swat model parameter
#'   files
#' @param i_par Index that gives the number of the curent parameter that is
#'   modified in this step
#' @param run_index Vector of the indices of runs that are performed
#' @param i_run Index that gives the number of the current run simulated in the
#'   respective thread
#'
#' @importFrom dplyr %>% filter
#' @importFrom tibble tribble
#'
#' @keywords internal
#'
modify_mgt_par <- function(parameter, model_parameter, file_meta,
                           i_par, run_index, i_run) {
  mgt_lookup <- tribble(
    ~par,           ~mgt_op,     ~mgt_i,
    "PLANT_ID",     1,           "MGT1",
    "CURYR_MAT",    1,           "MGT3",
    "HEAT_UNITS",   1,           "MGT4",
    "LAI_INIT",     1,           "MGT5",
    "BIO_INIT",     1,           "MGT6",
    "HI_TARG",      1,           "MGT7",
    "BIO_TARG",     1,           "MGT8",
    "CNOP_PLANT",   1,           "MGT9",
    "IRR_AMT",      2,           "MGT4",
    "FERT_ID",      3,           "MGT1",
    "FRT_KG",       3,           "MGT4",
    "FRT_SURFACE",  3,           "MGT5",
    "PEST_ID",      4,           "MGT1",
    "PST_KG",       4,           "MGT4",
    "CNOP_HRVKILL", 5,           "MGT4",
    "TILL_ID",      6,           "MGT1",
    "CNOP_TILL",    6,           "MGT4",
    "HARVEFF",      7,           "MGT4",
    "HI_OVR",       7,           "MGT5",
    "GRZ_DAYS",     9,           "MGT1",
    "MANURE_ID",    9,           "MGT2",
    "BIO_EAT",      9,           "MGT4",
    "BIO_TRMP",     9,           "MGT5",
    "MANURE_KG",    9,           "MGT6",
    "WSTRS_ID",     10,          "MGT1",
    "AUTO_WSTRS",   10,          "MGT4",
    "AFERT_ID",     11,          "MGT1",
    "AUTO_NSTRS",   11,          "MGT4",
    "AUTO_NAPP",    11,          "MGT5",
    "AUTO_NYR",     11,          "MGT6",
    "AUTO_EFF",     11,          "MGT7",
    "AFRT_SURFACE", 11,          "MGT8",
    "SWEEPEFF",     12,          "MGT4",
    "FR_CURB",      12,          "MGT5",
    "IMP_TRIG",     13,          "MGT1",
    "FERT_DAYS",    14,          "MGT1",
    "CFRT_ID",      14,          "MGT2",
    "IFRT_FREQ",    14,          "MGT3",
    "CFRT_KG",      14,          "MGT4")

  par_i <- parameter$definition[i_par, ]
  par_up_i <- parameter$values[[par_i$par_name]][run_index[i_run]]
  file_code_i <- par_i$file_expression %>%
    evaluate_expression(file_meta, .) %>%
    .[["file_code"]]

  mgt_i <- filter(mgt_lookup, par == par_i$parameter)

  idx_i <- model_parameter$mgt$mgt_table %>%
    filter(file_code %in% file_code_i) %>%
    filter(MGT_OP == mgt_i[["mgt_op"]]) %>%
    .[["idx"]]

  model_parameter$mgt$mgt_table[,mgt_i[["mgt_i"]]] <-
    model_parameter$mgt$mgt_table[,mgt_i[["mgt_i"]]] %>%
    .[[1]] %>%
    update_par(., par_up_i, par_i$change, idx_i)

  return(model_parameter)
}

#' Update parameter values according to the different options 'abs', 'rep', and
#' 'rel'
#'
#' @param par Vector with parameter values that are updated
#' @param par_up Value that is applied to the paramter values for updating
#' @param change Type of change, either: abs', 'rep', or 'rel'
#' @param to_chg Index vector that indicates the values of the parameter vector
#'   that should be updated
#'
#' @importFrom dplyr case_when
#'
#' @keywords internal
#'
update_par <- function(par, par_up, change, to_chg){
  par[to_chg] <- case_when(
    change == "relchg" ~ par[to_chg] * (1 + par_up),
    change == "pctchg" ~ par[to_chg] * (1 + par_up/100),
    change == "abschg" ~ par[to_chg] + par_up,
    change == "absval" ~ par_up
    )
  return(par)
}

#' Filter a parameter table for the specific expression if available
#'
#' @param par_table Parameter table
#' @param expr Expression to evaluate
#'
#' @keywords internal
#'
filter_spec_expr <- function(par_table, expr) {
  if(nchar(expr) > 0) {
    par_table <- evaluate_expression(par_table, expr)
  }
  return(par_table)
}
