defmodule CommonCore.Ecto.BatteryUUID do
  @moduledoc """

  This module defines an Ecto.Type for a UUID that
  is prefixed with `batt_`. It's autogenerate function
  generates a UUID that is sortable by time.

  It is a stripped down version of UUIDv7.

  It is designed to be used as the primary key for
  all tables in the system with better usability
  than the default UUID.

  It also accepts the standard UUID format.

  It's derived from Uniq and Ecto.UUID and
  ULIID. It's performance should match all of those.

  Case insensitive hex encoding is used
  """
  use Ecto.Type

  @type t :: <<_::296>>

  def type, do: :uuid

  @compile {:inline, c: 1}

  defp c(?0), do: ?0
  defp c(?1), do: ?1
  defp c(?2), do: ?2
  defp c(?3), do: ?3
  defp c(?4), do: ?4
  defp c(?5), do: ?5
  defp c(?6), do: ?6
  defp c(?7), do: ?7
  defp c(?8), do: ?8
  defp c(?9), do: ?9

  # Lowercase is expected
  defp c(?a), do: ?a
  defp c(?b), do: ?b
  defp c(?c), do: ?c
  defp c(?d), do: ?d
  defp c(?e), do: ?e
  defp c(?f), do: ?f

  # Case insensitive
  defp c(?A), do: ?a
  defp c(?B), do: ?b
  defp c(?C), do: ?c
  defp c(?D), do: ?d
  defp c(?E), do: ?e
  defp c(?F), do: ?f

  defp c(_), do: throw(:error)

  def cast(
        <<?b, ?a, ?t, ?t, ?_, a1, a2, a3, a4, a5, a6, a7, a8, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4, e1, e2, e3,
          e4, e5, e6, e7, e8, e9, e10, e11, e12>>
      ) do
    # Take in the batt_ prefixed and return the same
    <<?b, ?a, ?t, ?t, ?_, c(a1), c(a2), c(a3), c(a4), c(a5), c(a6), c(a7), c(a8), c(b1), c(b2), c(b3), c(b4), c(c1),
      c(c2), c(c3), c(c4), c(d1), c(d2), c(d3), c(d4), c(e1), c(e2), c(e3), c(e4), c(e5), c(e6), c(e7), c(e8), c(e9),
      c(e10), c(e11), c(e12)>>
  catch
    :error -> :error
  else
    result -> {:ok, result}
  end

  def cast(
        <<a1, a2, a3, a4, a5, a6, a7, a8, ?-, b1, b2, b3, b4, ?-, c1, c2, c3, c4, ?-, d1, d2, d3, d4, ?-, e1, e2, e3, e4,
          e5, e6, e7, e8, e9, e10, e11, e12>>
      ) do
    # Take in the dashed uuid form and return the batt_ prefixed
    # This shouldn't happen, but it's here for completeness
    cast(
      <<?b, ?a, ?t, ?t, ?_, a1, a2, a3, a4, a5, a6, a7, a8, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4, e1, e2, e3,
        e4, e5, e6, e7, e8, e9, e10, e11, e12>>
    )
  end

  # Take in the raw bytes and return the batt_ prefixed
  def cast(<<_::128>> = raw_uuid), do: {:ok, encode(raw_uuid)}

  # Assume empty is nil
  def cast(""), do: {:ok, nil}
  def cast(nil), do: {:ok, nil}
  def cast(_), do: :error

  # Converts a binary UUID to a our expected format (batt_ prefixed)
  def load(<<_::128>> = raw_uuid), do: {:ok, encode(raw_uuid)}
  def load(_), do: :error

  @compile {:inline, d: 1}

  defp d(?0), do: 0
  defp d(?1), do: 1
  defp d(?2), do: 2
  defp d(?3), do: 3
  defp d(?4), do: 4
  defp d(?5), do: 5
  defp d(?6), do: 6
  defp d(?7), do: 7
  defp d(?8), do: 8
  defp d(?9), do: 9
  # Lowercase is expected
  defp d(?a), do: 10
  defp d(?b), do: 11
  defp d(?c), do: 12
  defp d(?d), do: 13
  defp d(?e), do: 14
  defp d(?f), do: 15
  # Case Insensitive
  defp d(?A), do: 10
  defp d(?B), do: 11
  defp d(?C), do: 12
  defp d(?D), do: 13
  defp d(?E), do: 14
  defp d(?F), do: 15

  defp d(_), do: throw(:error)

  def dump(
        <<?b, ?a, ?t, ?t, ?_, a1, a2, a3, a4, a5, a6, a7, a8, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4, e1, e2, e3,
          e4, e5, e6, e7, e8, e9, e10, e11, e12>>
      ) do
    <<d(a1)::4, d(a2)::4, d(a3)::4, d(a4)::4, d(a5)::4, d(a6)::4, d(a7)::4, d(a8)::4, d(b1)::4, d(b2)::4, d(b3)::4,
      d(b4)::4, d(c1)::4, d(c2)::4, d(c3)::4, d(c4)::4, d(d1)::4, d(d2)::4, d(d3)::4, d(d4)::4, d(e1)::4, d(e2)::4,
      d(e3)::4, d(e4)::4, d(e5)::4, d(e6)::4, d(e7)::4, d(e8)::4, d(e9)::4, d(e10)::4, d(e11)::4, d(e12)::4>>
  catch
    :error -> :error
  else
    raw_uuid -> {:ok, raw_uuid}
  end

  def dump(_), do: :error

  def autogenerate do
    # This is a VERY stripped down uuidv7
    time = System.system_time(:millisecond)

    # We need an odd number of bits so chop up 80 bits int 12, 62, and 6.
    <<rand_msb::12, rand_lsb::62, _::6>> = :crypto.strong_rand_bytes(10)
    # This is uuid v7 rfc variant 2
    # The first 48 bits are the time in milliseconds so that this sorts on time
    # The next 4 bits are the version
    # The next 12 bits are random
    # The next 2 bits are the variant
    # The last 62 bits are random
    encode(<<time::big-unsigned-integer-size(48), 7::4, rand_msb::12, 2::2, rand_lsb::62>>)
  end

  @compile {:inline, e: 1}

  defp e(0), do: ?0
  defp e(1), do: ?1
  defp e(2), do: ?2
  defp e(3), do: ?3
  defp e(4), do: ?4
  defp e(5), do: ?5
  defp e(6), do: ?6
  defp e(7), do: ?7
  defp e(8), do: ?8
  defp e(9), do: ?9
  defp e(10), do: ?a
  defp e(11), do: ?b
  defp e(12), do: ?c
  defp e(13), do: ?d
  defp e(14), do: ?e
  defp e(15), do: ?f

  # Take in a raw binary and return the batt_ prefixed
  # We do this by splitting the binary into 4 bit chunks and converting them to hex
  # Then prefixing with batt_
  defp encode(
         <<a1::4, a2::4, a3::4, a4::4, a5::4, a6::4, a7::4, a8::4, b1::4, b2::4, b3::4, b4::4, c1::4, c2::4, c3::4, c4::4,
           d1::4, d2::4, d3::4, d4::4, e1::4, e2::4, e3::4, e4::4, e5::4, e6::4, e7::4, e8::4, e9::4, e10::4, e11::4,
           e12::4>>
       ) do
    <<?b, ?a, ?t, ?t, ?_, e(a1), e(a2), e(a3), e(a4), e(a5), e(a6), e(a7), e(a8), e(b1), e(b2), e(b3), e(b4), e(c1),
      e(c2), e(c3), e(c4), e(d1), e(d2), e(d3), e(d4), e(e1), e(e2), e(e3), e(e4), e(e5), e(e6), e(e7), e(e8), e(e9),
      e(e10), e(e11), e(e12)>>
  end
end
