using BelgianDataset 
using Test

@testset "BelgianDataset.jl" begin
    # analyze_partecipant_data("resources/2010_Willem_BELGIUM_participant_common.csv","resources/2010_Willem_BELGIUM_participant_extra.csv")
    analyze_contact_data("resources/2010_Willem_BELGIUM_participant_common.csv","resources/2010_Willem_BELGIUM_contact_common.csv")
end


