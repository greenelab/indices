import itertools
import pickle as pkl
import os

import argparse

from utils import build_graphs, parse_mesh_headings


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--data_dir',
                         help='The directory containing coci citations',
                         default='data/coci')
    parser.add_argument('--metadata_dir',
                        help='File from download_article_metadata containing info on the '
                             'articles to add to the network',
                        default='data/pubmed/efetch')
    parser.add_argument('--out_dir',
                        help='The location to save the resulting netoworks to',
                        default='data/networks')
    parser.add_argument('--include_first_degree',
                        help='Include the citations where only one of the two articles belong '
                             'to the MeSH heading ',
                        action='store_true')
    parser.add_argument('headings_to_process', nargs='+',
                        help='The MeSH headings to make pairwise networks from')
    args = parser.parse_args()

    if len(args.headings_to_process) < 2:
        parser.error('You must include at least two headings to build pairwise networks')

    headings_to_process = set(args.headings_to_process)
    heading_to_dois = parse_mesh_headings(args.metadata_dir, headings_to_process)

    paired_headings = {}
    for heading1, heading2 in itertools.combinations(sorted(list(heading_to_dois.keys())), 2):
        first_dois = heading_to_dois[heading1]
        second_dois = heading_to_dois[heading2]
        combined_dois = first_dois.union(second_dois)

        paired_headings[f'{heading1}+{heading2}'] = combined_dois

    heading_to_graph = build_graphs(args.data_dir, paired_headings, args.include_first_degree)

    for heading in heading_to_graph.keys():
        graph = heading_to_graph[heading]
        if args.include_first_degree:
            heading += '-first_degree'
        out_file_path = os.path.join(args.out_dir, heading + '.pkl')
        with open(out_file_path, 'wb') as out_file:
            pkl.dump(graph, out_file)
