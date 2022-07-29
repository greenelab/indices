import argparse
import os
import pickle as pkl
import re

import networkx as nx

from utils import parse_mesh_headings


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('in_file',
                        help='The file to be split',
                        default='data/networks')
    parser.add_argument('--metadata_dir',
                        help='File from download_article_metadata containing info on the '
                             'articles to add to the network',
                        default='data/pubmed/efetch')
    parser.add_argument('--out_dir',
                        help='The location to save the resulting network to',
                        default='data/networks')
    args = parser.parse_args()

    heading_to_doi = parse_mesh_headings(args.metadata_dir)

    file = args.in_file
    file_base = os.path.basename(file)
    file_noext = os.path.splitext(file_base)[0]
    shuffle_number = None
    shuffle_regex = '_[0-9]+.pkl'
    if re.search(shuffle_regex, file_base):
        shuffle_number = file_noext.split('_')[-1]
        headings = '_'.join(file_noext.split('_')[:-1])
        heading1, heading2 = headings.split('+')
    else:
        heading1, heading2 = file_noext.split('+')

    heading1_dois = [doi for doi in heading_to_doi[heading1]
                        if doi is not None and len(doi) > 0]
    heading2_dois = [doi for doi in heading_to_doi[heading2]
                        if doi is not None and len(doi) > 0]

    with open(file, 'rb') as file_handle:
        pairwise_network = pkl.load(file_handle)

    heading1_network = pairwise_network.subgraph(heading1_dois).copy()
    heading2_network = pairwise_network.subgraph(heading2_dois).copy()

    # Remove nodes with no edges (i.e. citations)
    heading1_network.remove_nodes_from(list(nx.isolates(heading1_network)))
    heading2_network.remove_nodes_from(list(nx.isolates(heading2_network)))

    if shuffle_number is None:
        filename1 = f'{heading1}-{heading2}.pkl'
        filename2 = f'{heading2}-{heading1}.pkl'
    else:
        filename1 = f'{heading1}-{heading2}_{shuffle_number}.pkl'
        filename2 = f'{heading2}-{heading1}_{shuffle_number}.pkl'

    with open(os.path.join(args.out_dir, filename1), 'wb') as out_file:
        pkl.dump(heading1_network, out_file)
    with open(os.path.join(args.out_dir, filename2), 'wb') as out_file:
        pkl.dump(heading2_network, out_file)
