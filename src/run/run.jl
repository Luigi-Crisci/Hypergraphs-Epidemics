using HypergraphsEpidemics

households = generate_dataset("resources/dataset_salerno.csv",1000,76,5)

mean = sum(h -> h.num_components, households) / length(households)

parameter = Contact_simulation_options(700, 200, 70 , 900,1)

start_simulation(
    "resources/dataset_salerno.csv",
    parameter
)
