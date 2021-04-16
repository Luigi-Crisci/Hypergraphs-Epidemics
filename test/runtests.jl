using BelgianDataset
using Test

@testset "BelgianDataset.jl" begin
    # join_partecipant_common_and_extra_datasets("resources/2010_Willem_BELGIUM_participant_common.csv","resources/2010_Willem_BELGIUM_participant_extra.csv")
    analyze_contact_data("resources/2010_Willem_BELGIUM_participant_common.csv","resources/2010_Willem_BELGIUM_participant_extra.csv","resources/2010_Willem_BELGIUM_contact_common.csv","resources/2010_Willem_BELGIUM_contact_extra.csv")
end






