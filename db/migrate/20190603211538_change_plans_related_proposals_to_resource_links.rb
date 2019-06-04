# frozen_string_literal: true

class ChangePlansRelatedProposalsToResourceLinks < ActiveRecord::Migration[5.2]
  def up
    Decidim::Plans::Plan.all.each do |plan|
      proposal_ids = ActiveRecord::Base.connection.execute(
        "SELECT decidim_proposal_id FROM decidim_plans_attached_proposals " \
        "WHERE decidim_plan_id = #{plan.id}"
      ).pluck("decidim_proposal_id")

      say("Linking proposals for plan: #{plan.id}")

      next unless proposal_ids.count.positive?

      say("--Proposal IDs: #{proposal_ids.join(",")}")

      plan.link_resources(
        Decidim::Proposals::Proposal.where(id: proposal_ids),
        "included_proposals"
      )
    end

    # Drop the unnecessary attached proposals table
    drop_table :decidim_plans_attached_proposals
  end

  def down
    # Re-create the attached proposals table
    create_table :decidim_plans_attached_proposals do |t|
      t.references :decidim_plan, index: true
      t.references :decidim_proposal, index: true

      t.timestamps
    end

    Decidim::Plans::Plan.all.each do |plan|
      say("Reverting attached proposals for plan: #{plan.id}")
      plan.linked_resources(:proposals, "included_proposals").each do |proposal|
        say("--Proposal ID: #{proposal.id}")
        ActiveRecord::Base.connection.execute(
          "INSERT INTO decidim_plans_attached_proposals " \
          "(decidim_plan_id, decidim_proposal_id, created_at, updated_at)" \
          "VALUES (#{plan.id}, #{proposal.id}, NOW(), NOW())"
        )
      end
    end
  end
end
