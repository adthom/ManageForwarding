# This file enables modules to be automatically managed by the Functions service.
# See https://aka.ms/functionsmanageddependency for additional information.
#
@{
    # For latest supported version, go to 'https://www.powershellgallery.com/packages/Az'.
    # To use the Az module in your function app, please uncomment the line below.
    'Az' = '6.*'
    'MicrosoftTeams' = '2.5.1'  # 2.3.1 and 2.5.1 currently are the only versions that have the required function
}