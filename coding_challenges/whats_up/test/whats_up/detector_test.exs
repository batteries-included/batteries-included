defmodule WhatsUp.DetectorTest do
  use WhatsUp.DataCase

  alias WhatsUp.Detector

  describe "sites" do
    alias WhatsUp.Detector.Site

    import WhatsUp.DetectorFixtures

    @invalid_attrs %{timeout: nil, url: nil}

    test "list_sites/0 returns all sites" do
      site = site_fixture()
      assert Detector.list_sites() == [site]
    end

    test "get_site!/1 returns the site with given id" do
      site = site_fixture()
      assert Detector.get_site!(site.id) == site
    end

    test "create_site/1 with valid data creates a site" do
      valid_attrs = %{timeout: 42, url: "https://www.my.url.com"}

      assert {:ok, %Site{} = site} = Detector.create_site(valid_attrs)
      assert site.timeout == 42
      assert site.url == "https://www.my.url.com"
    end

    test "create_site/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Detector.create_site(@invalid_attrs)
    end

    test "update_site/2 with valid data updates the site" do
      site = site_fixture()
      update_attrs = %{timeout: 43, url: "https://my.updated.url.com"}

      assert {:ok, %Site{} = site} = Detector.update_site(site, update_attrs)
      assert site.timeout == 43
      assert site.url == "https://my.updated.url.com"
    end

    test "update_site/2 with invalid data returns error changeset" do
      site = site_fixture()
      assert {:error, %Ecto.Changeset{}} = Detector.update_site(site, @invalid_attrs)
      assert site == Detector.get_site!(site.id)
    end

    test "delete_site/1 deletes the site" do
      site = site_fixture()
      assert {:ok, %Site{}} = Detector.delete_site(site)
      assert_raise Ecto.NoResultsError, fn -> Detector.get_site!(site.id) end
    end

    test "change_site/1 returns a site changeset" do
      site = site_fixture()
      assert %Ecto.Changeset{} = Detector.change_site(site)
    end
  end
end
