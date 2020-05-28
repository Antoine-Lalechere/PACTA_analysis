# web_tool_script.R

options(encoding = "UTF-8") 

pacman::p_load(tidyr, dplyr, scales, reshape2, tidyverse, readxl, tidyselect, r2dii.utils, fs, jsonlite)


# source("0_portfolio_test.R")
# source("0_graphing_functions.R")
# source("0_reporting_functions.R")
source("0_portfolio_input_check_functions.R")
source("0_global_functions.R")
source("0_web_functions.R")
source("0_json_functions.R")

if (rstudioapi::isAvailable()) {
  # portfolio_name_ref <- "Portfolio3"
  working_location <- dirname(rstudioapi::getActiveDocumentContext()$path)
  working_location <- gsub("�","",working_location)
} else {
  portfolio_name_ref = get_portfolio_name()
  working_location <- getwd()
}

working_location <- paste0(working_location, "/")



# just done once
# create_project_folder(project_name, twodii_internal, project_location_ext)

# replaced with web version
# set_project_paths(project_name, twodii_internal, project_location_ext)
set_web_parameters(file_path = paste0(working_location,"/parameter_files/WebParameters_example.yml"))

# just done once
# create_project_folder(project_name, twodii_internal, project_location_ext)

set_webtool_paths()

# just done once
# copy_files(project_name)

options(r2dii_config = paste0(par_file_path,"/AnalysisParameters.yml"))

set_global_parameters(paste0(par_file_path,"/AnalysisParameters.yml"))

# need to define an alternative location for data files
analysis_inputs_path <- set_analysis_inputs_path(twodii_internal, data_location_ext, dataprep_timestamp)


######################################################################

####################
#### DATA FILES ####
####################

# Files are first cleaned then saved for a faster read in time. 
# Set parameter to ensure data is reprocessed in "new_data" == TRUE in the parameter file
file_location <- paste0(analysis_inputs_path, "cleaned_files")

if(new_data == TRUE){
  currencies <- get_and_clean_currency_data()
  
  # fund_data <- get_and_clean_fund_data()
  fund_data <- data.frame()
  
  fin_data <- get_and_clean_fin_data()
  
  comp_fin_data <- get_and_clean_company_fin_data()
  
  # revenue_data <- get_and_clean_revenue_data()
  
  average_sector_intensity <- get_average_emission_data(inc_emission_factors)
  
  company_emissions <- get_company_emission_data(inc_emission_factors)
  
  
  save_cleaned_files(file_location,
                     currencies, 
                     fund_data,
                     fin_data,
                     comp_fin_data,
                     average_sector_intensity,
                     company_emissions)
  
  
  
  
}else{
  
  currencies <- read_rds(paste0(file_location, "/currencies.rda"))
  
  fund_data <- read_rds(paste0(file_location, "/fund_data.rda"))

  fin_data <- read_rds(paste0(file_location, "/fin_data.rda"))

  comp_fin_data <- read_rds(paste0(file_location, "/comp_fin_data.rda"))

  # revenue_data <- read_rds(paste0(file_location, "revenue_data.rda"))

  if (inc_emission_factors){
    average_sector_intensity <- read_rds(paste0(file_location, "/average_sector_intensity.rda"))

    company_emissions <- read_rds(paste0(file_location, "/company_emissions.rda"))
  }
}
####################
#### PORTFOLIOS ####
####################

portfolio_raw <- get_input_files()


portfolio <- process_raw_portfolio(portfolio_raw,
                                        fin_data,
                                        fund_data,
                                        currencies, 
                                        grouping_variables)


portfolio <- add_revenue_split(has_revenue, portfolio, revenue_data)

eq_portfolio <- create_portfolio_subset(portfolio, 
                                        "Equity", 
                                        comp_fin_data)

cb_portfolio <- create_portfolio_subset(portfolio, 
                                        "Bonds", 
                                        comp_fin_data)

portfolio_total <- add_portfolio_flags(portfolio)

portfolio_overview <- portfolio_summary(portfolio_total)

identify_missing_data(portfolio_total)

audit_file <- create_audit_file(portfolio_total, comp_fin_data)

# create_audit_chart(audit_file, proc_input_path)

# website_text(audit_file)

emissions_totals <- calculate_portfolio_emissions(inc_emission_factors,
                                                  audit_file,
                                                  fin_data, 
                                                  comp_fin_data,  
                                                  average_sector_intensity,
                                                  company_emissions)

################
#### SAVING ####
################

export_audit_information_jsons(folder_path = proc_input_path)
export_audit_graph_json(audit_file__ = audit_file, export_path_full = proc_input_path)
export_audit_invalid_json(portfolio_total,export_path_full = proc_input_path)
export_audit_textvar_json(portfolio_total, proc_input_path)


if(data_check(audit_file)){write_csv(audit_file, paste0(proc_input_path, "/", project_name,"_audit_file.csv"))}

if(data_check(portfolio_total)){write_rds(portfolio_total, paste0(proc_input_path, "/", project_name, "_total_portfolio.rda"))}
if(data_check(eq_portfolio)){write_rds(eq_portfolio, paste0(proc_input_path, "/", project_name, "_equity_portfolio.rda"))}
if(data_check(cb_portfolio)){write_rds(cb_portfolio, paste0(proc_input_path, "/", project_name, "_bonds_portfolio.rda"))}
if(data_check(portfolio_overview)){write_rds(portfolio_overview, paste0(proc_input_path, "/", project_name, "_overview_portfolio.rda"))}
if(data_check(audit_file)){write_rds(audit_file, paste0(proc_input_path, "/", project_name,"_audit_file.rda"))}
if(data_check(emissions_totals)){write_rds(emissions_totals, paste0(proc_input_path, "/", project_name, "_emissions.rda"))}
