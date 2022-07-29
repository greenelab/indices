import itertools

HEADINGS = ["botany", "developmental_biology", "genetics","microbiology", "ecology",
            # Informatics subheadings
            "cheminformatics", "computational_biology", "consumer_health_informatics","medical_informatics",
            # Algorithms subheadings
            "artificial_intelligence", "latent_class_analysis",
            ]

COCI_DIR = '/mnt/SlowData/coci'

SPLIT_HEADINGS = [h1 + '-' + h2 for h1, h2 in itertools.combinations(sorted(HEADINGS), 2)]
SPLIT_HEADINGS2 = [h2 + '-' + h1 for h1, h2 in itertools.combinations(sorted(HEADINGS), 2)]

wildcard_constraints:
    # Random seeds should be numbers
    shuffle="\d+",
    # The headings wildcard used in shuffle_networks can contain letters, underscores,
    # and dashes, but no other characters such as numbers
    heading="[a-z_-]+",
    heading1="[a-z_-]+",
    heading2="[a-z_-]+",

ruleorder: split_combined_shuffled_networks > shuffle_networks

rule all:
    input:
        expand("output/shuffle_results/{split_heading}_{shuffle}-pagerank.pkl",
                split_heading=SPLIT_HEADINGS, shuffle=list(range(100))),
        expand("output/shuffle_results/{split_heading}_{shuffle}-pagerank.pkl",
                split_heading=SPLIT_HEADINGS2, shuffle=list(range(100))),
        expand("output/{split_heading}-pagerank.pkl",
                split_heading=SPLIT_HEADINGS, shuffle=list(range(100))),
        expand("output/{split_heading}-pagerank.pkl",
                split_heading=SPLIT_HEADINGS2, shuffle=list(range(100))),


rule download_citation_data:
    output:
        COCI_DIR
    shell:
        "bash download_citations.sh"

rule download_article_metadata:
    output:
        expand("data/pubmed/efetch/{heading}.xml.xz",
                heading=HEADINGS)
    shell:
        "python download_article_metadata.py {wildcards.heading} --overwrite "

# This assumes that data/coci actually has data in it, but I don't really
# want to specify file names since the dataset updates over time
rule build_single_heading_networks:
    input:
        COCI_DIR
    output:
        expand("data/networks/{heading}.pkl",
               heading=HEADINGS)
    shell:
        "python indices/build_single_heading_networks.py "
        "--data_dir " + COCI_DIR

rule build_pairwise_networks:
    threads:
        8
    input:
        COCI_DIR
    output:
        ["data/networks/" + h1 + "+" + h2 + ".pkl" for h1, h2 in itertools.combinations(sorted(HEADINGS), 2)]
    shell:
        "python indices/build_pairwise_networks.py " + ' '.join(HEADINGS) + ' '
        " --data_dir " + COCI_DIR + " "


rule shuffle_networks:
    input:
        "data/networks/{heading}.pkl"
    output:
        ["data/shuffled_networks/{heading}_"+ str(i) + ".pkl" for i in range(100)]

    shell:
        "python indices/shuffle_graph.py {input} data/shuffled_networks"

rule split_combined_shuffled_networks:
    input:
        "data/shuffled_networks/{heading1}+{heading2}_{shuffle}.pkl"
    output:
        "data/shuffled_networks/{heading1}-{heading2}_{shuffle}.pkl",
        "data/shuffled_networks/{heading2}-{heading1}_{shuffle}.pkl"
    shell:
        "python indices/split_pairwise_network.py {input}"

rule split_combined_networks:
    input:
        "data/networks/{heading1}+{heading2}.pkl"
    output:
        "data/networks/{heading1}-{heading2}.pkl",
        "data/networks/{heading2}-{heading1}.pkl"
    shell:
        "python indices/split_pairwise_network.py {input}"

rule calculate_shuffled_pagerank:
    input:
        "data/shuffled_networks/{heading1}-{heading2}_{shuffle}.pkl"
    output:
        "output/shuffle_results/{heading1}-{heading2}_{shuffle}-pagerank.pkl"
    shell:
        "python indices/run_metric_on_graph.py {input} pagerank output/shuffle_results"

rule calculate_pagerank:
    input:
        "data/networks/{heading1}-{heading2}.pkl"
    output:
        "output/{heading1}-{heading2}-pagerank.pkl"
    shell:
        "python indices/run_metric_on_graph.py {input} pagerank output"
